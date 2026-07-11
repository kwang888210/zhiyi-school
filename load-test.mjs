/**
 * 轻量并发冒烟压测 —— 验证认证链路（JWT + Caffeine 状态缓存）在高并发下的表现
 * 用法：node load-test.mjs <token>
 */
const token = process.argv[2]
if (!token) { console.error('usage: node load-test.mjs <token>'); process.exit(1) }

const URL = 'http://localhost:8080/api/user/profile'
const TOTAL = 5000        // 总请求数
const CONCURRENCY = 500   // 并发窗口

let ok = 0, fail = 0
const latencies = []

async function worker(n) {
  for (let i = 0; i < n; i++) {
    const t0 = performance.now()
    try {
      const res = await fetch(URL, { headers: { Authorization: `Bearer ${token}` } })
      const body = await res.json()
      if (body.code === 200) ok++; else fail++
    } catch { fail++ }
    latencies.push(performance.now() - t0)
  }
}

const t0 = performance.now()
const per = Math.ceil(TOTAL / CONCURRENCY)
await Promise.all(Array.from({ length: CONCURRENCY }, () => worker(per)))
const wall = (performance.now() - t0) / 1000

latencies.sort((a, b) => a - b)
const p = (q) => latencies[Math.floor(latencies.length * q)].toFixed(1)
console.log(`total=${ok + fail} ok=${ok} fail=${fail}`)
console.log(`wall=${wall.toFixed(2)}s  qps=${((ok + fail) / wall).toFixed(0)}`)
console.log(`latency p50=${p(0.5)}ms p90=${p(0.9)}ms p99=${p(0.99)}ms`)
