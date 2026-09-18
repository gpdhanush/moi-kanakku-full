/**
 * Run async work over items with a fixed concurrency limit.
 * @template T, R
 * @param {T[]} items
 * @param {number} limit
 * @param {(item: T, index: number) => Promise<R>} fn
 * @returns {Promise<R[]>}
 */
async function mapWithConcurrency(items, limit, fn) {
    const list = Array.isArray(items) ? items : [];
    const concurrency = Math.max(1, Math.min(Number(limit) || 1, list.length || 1));
    const results = new Array(list.length);
    let nextIndex = 0;

    async function worker() {
        while (nextIndex < list.length) {
            const index = nextIndex++;
            results[index] = await fn(list[index], index);
        }
    }

    const workers = Array.from(
        { length: Math.min(concurrency, list.length) },
        () => worker()
    );
    await Promise.all(workers);
    return results;
}

module.exports = {
    mapWithConcurrency,
};
