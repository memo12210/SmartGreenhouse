import logging
import time

from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import start_http_server, Counter, Histogram
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.core.config import settings

logger = logging.getLogger(__name__)

# Prometheus Metrics
REQUEST_COUNT = Counter("http_requests_total", "Total HTTP Requests", ["method", "endpoint", "http_status"])
REQUEST_LATENCY = Histogram("http_request_duration_seconds", "HTTP Request Latency", ["method", "endpoint"])
TELEMETRY_INGESTED = Counter("telemetry_ingested_total", "Total Telemetry Ingested", ["device_type"])

# Port the Prometheus client exposes metrics on (mapped to host 8008 in compose).
METRICS_PORT = 8000
_metrics_server_started = False


class PrometheusMiddleware(BaseHTTPMiddleware):
    """Populates the request count/latency metrics for every HTTP request."""

    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        duration = time.perf_counter() - start

        # Use the matched route template (e.g. "/api/v1/devices/{device_id}")
        # rather than the raw path to keep label cardinality bounded.
        route = request.scope.get("route")
        endpoint = getattr(route, "path", request.url.path)

        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=endpoint,
            http_status=response.status_code,
        ).inc()
        REQUEST_LATENCY.labels(method=request.method, endpoint=endpoint).observe(duration)
        return response


def setup_observability(app: FastAPI):
    # Logging
    logging.basicConfig(level=logging.INFO)

    # OpenTelemetry Tracing
    resource = Resource(attributes={
        SERVICE_NAME: settings.OTEL_SERVICE_NAME
    })

    provider = TracerProvider(resource=resource)
    processor = BatchSpanProcessor(OTLPSpanExporter(endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT, insecure=True))
    provider.add_span_processor(processor)
    trace.set_tracer_provider(provider)

    FastAPIInstrumentor.instrument_app(app)

    # Wire the custom Prometheus counters/histogram into the request lifecycle.
    app.add_middleware(PrometheusMiddleware)


def start_metrics_server():
    """Start the Prometheus metrics HTTP endpoint.

    Called from the app lifespan (not at import time) so that importing this
    module — e.g. during tests — does not bind a network port as a side effect.
    """
    global _metrics_server_started
    if _metrics_server_started:
        return
    try:
        start_http_server(METRICS_PORT)
        _metrics_server_started = True
    except OSError as e:
        logger.error(f"Failed to start Prometheus metrics server on port {METRICS_PORT}: {e}")
