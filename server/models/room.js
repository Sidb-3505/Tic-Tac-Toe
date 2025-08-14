const mongoose = require('mongoose');
const playerSchema = require('./player');

const roomSchema = new mongoose.Schema({
    occupancy: {
        type: Number,
        default: 2,
    },
    maxRounds: {
        type: Number,
        default: 5,
    },
    currentRound: {
        required: true,
        type: Number,
        default: 1,
    },
    // to give it a list of players
    players: [playerSchema],
    // to check if the game is already started
    isJoin: {
        type: Boolean,
        default: true
    },
    // to show the turn of curr player
    turn: playerSchema,
    // tracking which user's turn it is
    turnIndex: {
        type: Number,
        default: 0,
        // for room creater idx: 1
        // for other player idx: 0
    }
});

const roomModel = mongoose.model('Room', roomSchema);

module.exports = roomModel;