const Model = require('../models/defaults');
const { validateUuid, sendUuidError } = require('../helpers/idParams');
const cache = require('../utils/cache');

exports.controller = {

    totalAmount: async (req, res) => {
        try {
            const { userId } = req.body;
            
            if (!userId) {
                return res.status(400).json({ 
                    responseType: "F", 
                    responseValue: { message: 'User ID is required!' } 
                });
            }

            const idCheck = validateUuid(userId, 'userId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);

            const cacheKey = `user:totalAmount:${userId}`;
            const cachedResponse = cache.get(cacheKey);
            if (cachedResponse) {
                return res.status(200).json(cachedResponse);
            }
            
            const result = await Model.totalAmount(userId);
            if (!result || result.length === 0) {
                return res.status(404).json({ 
                    responseType: "F", 
                    responseValue: { message: 'No details found.' } 
                });
            }
            
            const data = result[0];
            const response = {
                amounts: {
                    invest: parseFloat(data.invest_amount || 0),
                    return: parseFloat(data.return_amount || 0),
                    net: parseFloat((data.invest_amount || 0) - (data.return_amount || 0))
                },
                things: {
                    invest: parseInt(data.invest_things || 0),
                    return: parseInt(data.return_things || 0)
                },
                members: {
                    total: parseInt(data.total_members || 0),
                    invest: parseInt(data.invest_members || 0),
                    return: parseInt(data.return_members || 0)
                }
            };
            
            const finalResponse = { responseType: "S", responseValue: response };
            cache.set(cacheKey, finalResponse, cache.TTL.USER_STATS);
            return res.status(200).json(finalResponse);
        } catch (error) {
            return res.status(500).json({ responseType: "F", responseValue: { message: error.toString() } });
        }
    },
}
