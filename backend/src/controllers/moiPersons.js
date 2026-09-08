const Model = require("../models/moiPersons");
const User = require("../models/user");
const { validateUuid, validateUuidFields, sendUuidError } = require("../helpers/idParams");

const formatPersonSummary = (person) => ({
  id: person.mp_id,
  firstName: person.mp_first_name,
  secondName: person.mp_second_name,
  business: person.mp_business,
  city: person.mp_city,
  mobile: person.mp_mobile,
});

const formatPersonDetails = (person) => ({
  ...formatPersonSummary(person),
  userId: person.mp_um_id,
});

const formatAdminPerson = (person) => ({
  ...formatPersonDetails(person),
  userName: person.userName || null,
  userEmail: person.userEmail || null,
  userMobile: person.userMobile || null,
  createdAt: person.created_at || person.mp_create_dt || null,
  updatedAt: person.updated_at || person.mp_update_dt || null,
});

exports.controller = {
  list: async (req, res) => {
    const { userId, search } = req.body;
    try {
      const idCheck = validateUuid(userId, "userId");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified user not found!" },
        });
      }

      const persons = await Model.readAll(userId, search);

      if (persons.length === 0) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "No details found." },
        });
      }

      const transformed = persons.map(formatPersonSummary);

      return res.status(200).json({
        responseType: "S",
        count: transformed.length,
        responseValue: transformed,
      });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  create: async (req, res) => {
    try {
      const { userId, firstName, secondName, business, city, mobile } =
        req.body;

      if (!userId || !firstName) {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "Required fields are missing." },
        });
      }

      const idCheck = validateUuid(userId, "userId");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified user not found!" },
        });
      }

      // Check if person with same mobile already exists
      if (mobile) {
        const existing = await Model.findByMobile(userId, mobile);
        if (existing) {
          return res.status(400).json({
            responseType: "F",
            responseValue: {
              message: "A person with this mobile number already exists.",
              personId: existing.mp_id,
            },
          });
        }
      }

      // Check for duplicate person (same firstName, secondName, business, city, mobile)
      const duplicate = await Model.findDuplicate(
        userId,
        firstName,
        secondName,
        business,
        city,
        mobile,
      );
      if (duplicate) {
        return res.status(400).json({
          responseType: "F",
          responseValue: {
            message: "A person with these details already exists.",
            personId: duplicate.mp_id,
          },
        });
      }

      const data = {
        userId,
        firstName,
        secondName,
        business,
        city,
        mobile,
      };

      const result = await Model.create(data);
      if (result && result.insertId) {
        return res.status(200).json({
          responseType: "S",
          responseValue: {
            message: "Person added successfully.",
            id: result.insertId,
          },
        });
      } else {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Failed to save data." },
        });
      }
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  update: async (req, res) => {
    try {
      const { userId, id, firstName, secondName, business, city, mobile } =
        req.body;
      if (!userId || !id || !firstName) {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "Required fields are missing." },
        });
      }

      const idCheck = validateUuidFields({ userId, id });
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified user not found!" },
        });
      }

      const existing = await Model.readById(id);
      if (!existing) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified person not found!" },
        });
      }

      // Check if mobile is being changed and if it conflicts with another person
      if (mobile && mobile !== existing.mobile) {
        const conflict = await Model.findByMobile(userId, mobile);
        if (conflict && conflict.id !== id) {
          return res.status(400).json({
            responseType: "F",
            responseValue: {
              message: "This mobile number is already in use.",
            },
          });
        }
      }

      const data = {
        id,
        firstName,
        secondName,
        business,
        city,
        mobile,
      };

      const result = await Model.update(data);
      if (result) {
        return res.status(200).json({
          responseType: "S",
          responseValue: {
            message: "Person details updated successfully.",
          },
        });
      } else {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Failed to update data." },
        });
      }
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  delete: async (req, res) => {
    try {
      const id = req.params.id;

      if (!id || id.trim() === "") {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "Person ID not provided." },
        });
      }

      const idCheck = validateUuid(id, "id");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const existing = await Model.readById(id);

      if (!existing) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified person not found!" },
        });
      }

      const result = await Model.delete(id);
      if (result && result.affectedRows > 0) {
        return res.status(200).json({
          responseType: "S",
          responseValue: { message: "Person deleted successfully." },
        });
      } else {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Could not delete this person!" },
        });
      }
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  getById: async (req, res) => {
    try {
      const id = req.params.id;

      if (!id || id.trim() === "") {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "Person ID not provided." },
        });
      }

      const idCheck = validateUuid(id, "id");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const person = await Model.readById(id);

      if (!person) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified person not found!" },
        });
      }

      return res.status(200).json({
        responseType: "S",
        responseValue: formatPersonDetails(person),
      });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  getPersonDetails: async (req, res) => {
    try {
      const { userId } = req.body;
      const idCheck = validateUuid(userId, "userId");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified user not found!" },
        });
      }

      const person = await Model.getPersonDetails(userId);

      if (!person) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Person details not found." },
        });
      }

      return res.status(200).json({
        responseType: "S",
        responseValue: formatPersonSummary(person),
      });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  adminList: async (req, res) => {
    try {
      const search = req.query.search ? String(req.query.search).trim() : null;
      const userId = req.query.userId ? String(req.query.userId).trim() : null;
      if (userId) {
        const idCheck = validateUuid(userId, "userId");
        if (!idCheck.ok) return sendUuidError(res, idCheck.message);
      }
      const requestedLimit = Number.parseInt(req.query.limit, 10);
      const requestedOffset = Number.parseInt(req.query.offset, 10);
      const limit =
        Number.isInteger(requestedLimit) && requestedLimit > 0
          ? Math.min(requestedLimit, 500)
          : 100;
      const offset =
        Number.isInteger(requestedOffset) && requestedOffset >= 0
          ? requestedOffset
          : 0;

      const persons = await Model.readAllForAdmin({
        search: search || null,
        userId: userId || null,
        limit,
        offset,
      });

      return res.status(200).json({
        responseType: "S",
        count: persons.length,
        responseValue: persons.map(formatAdminPerson),
      });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  adminGetById: async (req, res) => {
    try {
      const id = req.params.id;

      if (!id || id.trim() === "") {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "Person ID not provided." },
        });
      }

      const idCheck = validateUuid(id, "id");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const person = await Model.readByIdForAdmin(id);

      if (!person) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified person not found!" },
        });
      }

      return res.status(200).json({
        responseType: "S",
        responseValue: formatAdminPerson(person),
      });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  adminGetByUserId: async (req, res) => {
    try {
      const userId = req.params.id;
      if (!userId || userId.trim() === "") {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "User ID not provided." },
        });
      }

      const idCheck = validateUuid(userId, "userId");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const persons = await Model.readByUserIdForAdmin(userId);

      return res.status(200).json({
        responseType: "S",
        count: persons.length,
        responseValue: persons.map(formatAdminPerson),
      });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  adminUpdate: async (req, res) => {
    try {
      const { id, firstName, secondName, business, city, mobile } = req.body;

      if (!id || !firstName) {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "Required fields are missing." },
        });
      }

      const idCheck = validateUuid(id, 'id');
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const existing = await Model.readById(id);
      if (!existing) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified person not found!" },
        });
      }

      const personUserId =
        existing.user_id || existing.userId || existing.mp_um_id;
      if (mobile && mobile !== existing.mobile) {
        const conflict = await Model.findByMobile(personUserId, mobile);
        if (conflict && conflict.id !== id) {
          return res.status(400).json({
            responseType: "F",
            responseValue: {
              message: "This mobile number is already in use.",
            },
          });
        }
      }

      const result = await Model.update({
        id,
        firstName,
        secondName,
        business,
        city,
        mobile,
      });

      if (!result || result.affectedRows <= 0) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Failed to update data." },
        });
      }

      const updatedPerson = await Model.readByIdForAdmin(id);

      return res.status(200).json({
        responseType: "S",
        responseValue: {
          message: "Person details updated successfully.",
          person: updatedPerson ? formatAdminPerson(updatedPerson) : null,
        },
      });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  adminDelete: async (req, res) => {
    try {
      const id = req.params.id;

      if (!id || id.trim() === "") {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "Person ID not provided." },
        });
      }

      const idCheck = validateUuid(id, 'id');
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const existing = await Model.readByIdForAdmin(id);

      if (!existing) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Specified person not found!" },
        });
      }

      const result = await Model.delete(id);
      if (result && result.affectedRows > 0) {
        return res.status(200).json({
          responseType: "S",
          responseValue: {
            message: "Person deleted successfully.",
            id,
          },
        });
      }

      return res.status(404).json({
        responseType: "F",
        responseValue: { message: "Could not delete this person!" },
      });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },
};
