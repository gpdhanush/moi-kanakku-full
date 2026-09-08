const db = require('../config/database');
const logger = require('../config/logger');
const cache = require('../utils/cache');

exports.controller = {
    /**
     * Get dashboard statistics and counts
     * Returns various metrics for admin dashboard
     */
    getDashboard: async (req, res) => {
        try {
            const cacheKey = 'dashboard:stats';
            const cachedDashboard = cache.get(cacheKey);
            if (cachedDashboard) {
                return res.status(200).json(cachedDashboard);
            }

            // Execute optimized, consolidated count queries in parallel
            const [
                usersResult,
                personsResult,
                transactionFunctionsResult,
                transactionsSummaryResult,
                notificationsResult,
                feedbacksResult,
                defaultFunctionsResult,
                upcomingFunctionsResult,
                userDevicesResult
            ] = await Promise.all([
                // Total users
                db.query('SELECT COUNT(*) as count FROM users WHERE is_deleted = 0 OR is_deleted IS NULL'),
                
                // Total persons
                db.query('SELECT COUNT(*) as count FROM persons'),
                
                // Total transaction functions
                db.query('SELECT COUNT(*) as count FROM transaction_functions'),
                
                // Consolidated transactions summary (Total, Invest, Return in a single query)
                db.query(`SELECT 
                            COUNT(*) as total_count,
                            SUM(CASE WHEN type = 'invest' THEN 1 ELSE 0 END) as invest_count,
                            SUM(CASE WHEN type = 'return' THEN 1 ELSE 0 END) as return_count
                         FROM transactions 
                         WHERE is_deleted = 0 OR is_deleted IS NULL`),
                
                // Notification counts (total, read, unread)
                db.query(`SELECT 
                            COUNT(*) as total,
                            SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as read_count,
                            SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_count
                         FROM notifications 
                         WHERE is_deleted = 0 OR is_deleted IS NULL`),
                
                // Total feedbacks
                db.query('SELECT COUNT(*) as count FROM feedbacks WHERE is_deleted = 0 OR is_deleted IS NULL'),
                
                // Total default functions
                db.query('SELECT COUNT(*) as count FROM default_functions'),
                
                // Total upcoming functions
                db.query('SELECT COUNT(*) as count FROM upcoming_functions'),
                
                // Total user devices
                db.query('SELECT COUNT(*) as count FROM user_devices WHERE is_deleted = 0 OR is_deleted IS NULL')
            ]);

            const transStats = transactionsSummaryResult[0][0] || {};

            // Parse results - Simple format with title and count only
            const dashboard = [
                {
                    title: "Total Users",
                    count: usersResult[0][0]?.count || 0
                },
                {
                    title: "Total Persons",
                    count: personsResult[0][0]?.count || 0
                },
                {
                    title: "Total Transaction Functions",
                    count: transactionFunctionsResult[0][0]?.count || 0
                },
                {
                    title: "Total Transactions",
                    count: Number(transStats.total_count) || 0
                },
                {
                    title: "Total Invest Transactions",
                    count: Number(transStats.invest_count) || 0
                },
                {
                    title: "Total Return Transactions",
                    count: Number(transStats.return_count) || 0
                },
                {
                    title: "Total Notifications",
                    count: notificationsResult[0][0]?.total || 0
                },
                {
                    title: "Read Notifications",
                    count: notificationsResult[0][0]?.read_count || 0
                },
                {
                    title: "Unread Notifications",
                    count: notificationsResult[0][0]?.unread_count || 0
                },
                {
                    title: "Total Feedbacks",
                    count: feedbacksResult[0][0]?.count || 0
                },
                {
                    title: "Total Default Functions",
                    count: defaultFunctionsResult[0][0]?.count || 0
                },
                {
                    title: "Total Upcoming Functions",
                    count: upcomingFunctionsResult[0][0]?.count || 0
                },
                {
                    title: "Total User Devices",
                    count: userDevicesResult[0][0]?.count || 0
                }
            ];

            logger.info('Dashboard statistics retrieved successfully');
            
            const response = {
                responseType: "S",
                responseValue: dashboard
            };
            cache.set(cacheKey, response, cache.TTL.DASHBOARD);
            return res.status(200).json(response);
        } catch (error) {
            logger.error('Error fetching dashboard statistics:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Get detailed dashboard with additional metrics
     */
    getDashboardDetailed: async (req, res) => {
        try {
            const cacheKey = 'dashboard:detailed';
            const cachedDetailed = cache.get(cacheKey);
            if (cachedDetailed) {
                return res.status(200).json(cachedDetailed);
            }

            // Execute optimized, consolidated count queries in parallel
            const [
                usersSummaryResult,
                personsResult,
                transactionFunctionsResult,
                transactionsSummaryResult,
                notificationsResult,
                feedbacksResult,
                defaultFunctionsResult,
                upcomingFunctionsResult,
                userDevicesSummaryResult
            ] = await Promise.all([
                // Users summary (Total & 7-day recent)
                db.query(`SELECT 
                            COUNT(*) as count,
                            SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as recent_7days
                          FROM users 
                          WHERE is_deleted = 0 OR is_deleted IS NULL`),
                
                // Total persons
                db.query('SELECT COUNT(*) as count FROM persons'),
                
                // Total transaction functions
                db.query('SELECT COUNT(*) as count FROM transaction_functions'),
                
                // Consolidated transactions summary (Total, Invest, Return, Amounts, & Recent 7-day metrics in 1 query)
                db.query(`SELECT 
                            COUNT(*) as total_count,
                            SUM(CASE WHEN type = 'invest' THEN 1 ELSE 0 END) as invest_count,
                            SUM(CASE WHEN type = 'invest' THEN amount ELSE 0 END) as invest_total_amount,
                            SUM(CASE WHEN type = 'return' THEN 1 ELSE 0 END) as return_count,
                            SUM(CASE WHEN type = 'return' THEN amount ELSE 0 END) as return_total_amount,
                            SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as recent_7days_count,
                            SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN amount ELSE 0 END) as recent_7days_amount
                         FROM transactions 
                         WHERE is_deleted = 0 OR is_deleted IS NULL`),
                
                // Notification counts (total, read, unread)
                db.query(`SELECT 
                            COUNT(*) as total,
                            SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as read_count,
                            SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_count
                         FROM notifications 
                         WHERE is_deleted = 0 OR is_deleted IS NULL`),
                
                // Total feedbacks
                db.query('SELECT COUNT(*) as count FROM feedbacks WHERE is_deleted = 0 OR is_deleted IS NULL'),
                
                // Total default functions
                db.query('SELECT COUNT(*) as count FROM default_functions'),
                
                // Total upcoming functions
                db.query('SELECT COUNT(*) as count FROM upcoming_functions'),
                
                // User devices summary (Total & Active 24h)
                db.query(`SELECT 
                            COUNT(*) as count,
                            SUM(CASE WHEN is_active = 1 AND last_used_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 ELSE 0 END) as active_24h
                          FROM user_devices 
                          WHERE is_deleted = 0 OR is_deleted IS NULL`)
            ]);

            const usersStats = usersSummaryResult[0][0] || {};
            const transStats = transactionsSummaryResult[0][0] || {};
            const deviceStats = userDevicesSummaryResult[0][0] || {};

            // Parse results
            const dashboard = [
                {
                    title: "Total Users",
                    count: Number(usersStats.count) || 0,
                    recent_7days: Number(usersStats.recent_7days) || 0
                },
                {
                    title: "Total Persons",
                    count: personsResult[0][0]?.count || 0
                },
                {
                    title: "Total Transaction Functions",
                    count: transactionFunctionsResult[0][0]?.count || 0
                },
                {
                    title: "Total Transactions",
                    count: Number(transStats.total_count) || 0,
                    recent_7days: {
                        count: Number(transStats.recent_7days_count) || 0,
                        total_amount: Number(transStats.recent_7days_amount) || 0
                    }
                },
                {
                    title: "Total Invest Transactions",
                    count: Number(transStats.invest_count) || 0,
                    total_amount: Number(transStats.invest_total_amount) || 0
                },
                {
                    title: "Total Return Transactions",
                    count: Number(transStats.return_count) || 0,
                    total_amount: Number(transStats.return_total_amount) || 0
                },
                {
                    title: "Total Notifications",
                    count: notificationsResult[0][0]?.total || 0,
                    read: notificationsResult[0][0]?.read_count || 0,
                    unread: notificationsResult[0][0]?.unread_count || 0
                },
                {
                    title: "Total Feedbacks",
                    count: feedbacksResult[0][0]?.count || 0
                },
                {
                    title: "Total Default Functions",
                    count: defaultFunctionsResult[0][0]?.count || 0
                },
                {
                    title: "Total Upcoming Functions",
                    count: upcomingFunctionsResult[0][0]?.count || 0
                },
                {
                    title: "Total User Devices",
                    count: Number(deviceStats.count) || 0,
                    active_24h: Number(deviceStats.active_24h) || 0
                }
            ];

            logger.info('Detailed dashboard statistics retrieved successfully');
            
            const response = {
                responseType: "S",
                responseValue: dashboard
            };
            cache.set(cacheKey, response, cache.TTL.DASHBOARD);
            return res.status(200).json(response);
        } catch (error) {
            logger.error('Error fetching detailed dashboard statistics:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    }
};
