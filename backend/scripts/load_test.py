from __future__ import annotations

import argparse
import json
import statistics
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed


def make_request(
    *,
    method: str,
    url: str,
    headers: dict[str, str],
    body: dict | None,
    timeout: float,
) -> tuple[bool, float, int | None, str]:
    request_body = None
    if body is not None:
        request_body = json.dumps(body).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=request_body,
        headers=headers,
        method=method,
    )

    started = time.perf_counter()
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            response.read()
            elapsed = time.perf_counter() - started
            return True, elapsed, response.getcode(), ""
    except urllib.error.HTTPError as exc:
        elapsed = time.perf_counter() - started
        return False, elapsed, exc.code, str(exc)
    except Exception as exc:  # pragma: no cover - runtime helper
        elapsed = time.perf_counter() - started
        return False, elapsed, None, str(exc)


def resolve_disease_id(base_url: str, timeout: float) -> int:
    request = urllib.request.Request(
        f"{base_url}/api/diseases/popular/?limit=1",
        method="GET",
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read().decode("utf-8"))
    diseases = payload.get("diseases") or []
    if not diseases:
        raise RuntimeError(
            "Popular diseases endpoint returned no diseases. Load initial data first."
        )
    return int(diseases[0]["id"])


def run_case(
    *,
    name: str,
    method: str,
    url: str,
    headers: dict[str, str],
    body: dict | None,
    requests_count: int,
    concurrency: int,
    timeout: float,
) -> dict:
    durations: list[float] = []
    failures: list[str] = []
    status_codes: dict[int | None, int] = {}
    started = time.perf_counter()

    with ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = [
            executor.submit(
                make_request,
                method=method,
                url=url,
                headers=headers,
                body=body,
                timeout=timeout,
            )
            for _ in range(requests_count)
        ]
        for future in as_completed(futures):
            ok, elapsed, status_code, error_text = future.result()
            durations.append(elapsed)
            status_codes[status_code] = status_codes.get(status_code, 0) + 1
            if not ok:
                failures.append(error_text)

    total_time = time.perf_counter() - started
    successful = requests_count - len(failures)
    return {
        "name": name,
        "url": url,
        "method": method,
        "requests": requests_count,
        "concurrency": concurrency,
        "success": successful,
        "failures": len(failures),
        "status_codes": status_codes,
        "total_time_sec": round(total_time, 3),
        "rps": round(successful / total_time, 2) if total_time else 0.0,
        "avg_ms": round(statistics.mean(durations) * 1000, 2),
        "p95_ms": round(statistics.quantiles(durations, n=20)[18] * 1000, 2),
        "max_ms": round(max(durations) * 1000, 2),
        "sample_error": failures[0] if failures else "",
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Minimal concurrent load test for key API endpoints."
    )
    parser.add_argument(
        "--base-url",
        default="http://127.0.0.1:8000",
        help="Base URL of deployed backend.",
    )
    parser.add_argument(
        "--requests",
        type=int,
        default=200,
        help="Number of requests per endpoint.",
    )
    parser.add_argument(
        "--concurrency",
        type=int,
        default=50,
        help="Concurrent workers per endpoint.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=10.0,
        help="Per-request timeout in seconds.",
    )
    args = parser.parse_args()

    base_url = args.base_url.rstrip("/")
    disease_id = resolve_disease_id(base_url, args.timeout)

    cases = [
        {
            "name": "search",
            "method": "POST",
            "url": f"{base_url}/api/search/",
            "headers": {"Content-Type": "application/json"},
            "body": {"symptoms": ["Головная боль", "Тошнота"]},
        },
        {
            "name": "popular_diseases",
            "method": "GET",
            "url": f"{base_url}/api/diseases/popular/?limit=10",
            "headers": {},
            "body": None,
        },
        {
            "name": "disease_detail",
            "method": "GET",
            "url": f"{base_url}/api/diseases/{disease_id}/",
            "headers": {},
            "body": None,
        },
    ]

    results = [
        run_case(
            name=case["name"],
            method=case["method"],
            url=case["url"],
            headers=case["headers"],
            body=case["body"],
            requests_count=args.requests,
            concurrency=args.concurrency,
            timeout=args.timeout,
        )
        for case in cases
    ]
    print(json.dumps({"base_url": base_url, "results": results}, indent=2))


if __name__ == "__main__":
    main()
