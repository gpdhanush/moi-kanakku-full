const db = require('../config/database');
const { generateUUID, toBinaryUUID, fromBinaryUUID } = require('../helpers/uuid');
const { getDbIdMode } = require('../helpers/dbIdMode');
const cache = require('../utils/cache');
const table = 'default_functions';

function clearDefaultFunctionsCache(id = null) {
    cache.del('default_functions:all');
    if (id) cache.del(`default_functions:id:${id}`);
}

const Model = {
    async create(name) {
        const idMode = await getDbIdMode(db);
        let insertId;
        if (idMode === 'uuid') {
            const id = generateUUID();
            await db.query(
                `INSERT INTO ${table} (id, name) VALUES (?, ?)`,
                [toBinaryUUID(id), name]
            );
            insertId = String(id);
        } else {
            const [result] = await db.query(
                `INSERT INTO ${table} (name) VALUES (?)`,
                [name]
            );
            insertId = String(result.insertId);
        }
        clearDefaultFunctionsCache();
        return { insertId };
    },

    // Read all global default functions (cached for 5 mins)
    async readAll() {
        return cache.getOrSet('default_functions:all', async () => {
            const [rows] = await db.query(
                `SELECT id, name, is_deleted, created_at, updated_at FROM ${table} WHERE is_deleted = 0 ORDER BY name ASC`
            );
            return rows.map(r => ({
                id: fromBinaryUUID(r.id),
                name: r.name,
                isDeleted: r.is_deleted,
                createdAt: r.created_at,
                updatedAt: r.updated_at
            }));
        }, cache.TTL.DEFAULTS);
    },

    async readById(id) {
        if (!id) return null;
        const cacheKey = `default_functions:id:${id}`;
        return cache.getOrSet(cacheKey, async () => {
            const [rows] = await db.query(
                `SELECT id, name, is_deleted, created_at, updated_at FROM ${table} WHERE id = ? AND is_deleted = 0`,
                [toBinaryUUID(id)]
            );
            if (rows.length === 0) return null;
            const r = rows[0];
            return {
                id: fromBinaryUUID(r.id),
                name: r.name,
                isDeleted: r.is_deleted,
                createdAt: r.created_at,
                updatedAt: r.updated_at
            };
        }, cache.TTL.DEFAULTS);
    },

    async update(id, name) {
        const [result] = await db.query(`UPDATE ${table} SET name = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`, [name, toBinaryUUID(id)]);
        if (result.affectedRows > 0) {
            clearDefaultFunctionsCache(id);
        }
        return result.affectedRows > 0;
    },

    async delete(id) {
        const [result] = await db.query(`UPDATE ${table} SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP WHERE id = ?`, [toBinaryUUID(id)]);
        if (result.affectedRows > 0) {
            clearDefaultFunctionsCache(id);
        }
        return result.affectedRows > 0;
    }
};

module.exports = Model;

