// importing the modules
require("dotenv").config();
const express = require("express");
const http = require("http");
const cors = require("cors");
const mongoose = require("mongoose");
const { Server } = require("socket.io");

const app = express();
const port = process.env.PORT || 3000;
const server = http.createServer(app);
const Room = require("./models/room");

// CORS: read from env (comma-separated origins)
const allowed = (process.env.CORS_ORIGIN || "")
    .split(",")
    .map(s => s.trim())
    .filter(Boolean);

const io = new Server(server, {
    cors: { origin: allowed.length ? allowed : "*", methods: ["GET", "POST"] },
});

// middleware
app.use(cors({ origin: allowed.length ? allowed : "*", credentials: true }));
app.use(express.json());

// ----- MongoDB (from env only) -----
const { MONGODB_URI } = process.env;
if (!MONGODB_URI) {
    console.error("❌ Missing MONGODB_URI env var");
    process.exit(1);
}
mongoose
    .connect(MONGODB_URI)
    .then(() => console.log("✅ Database connection successful"))
    .catch((e) => {
        console.error("❌ MongoDB connect error:", e.message);
        process.exit(1);
    });

// ----- Socket.io handlers (your logic kept) -----
io.on("connection", (socket) => {
    console.log(`Socket connected: ${socket.id}`);

    socket.on("createRoom", async ({ nickname }) => {
        try {
            let room = new Room();
            let player = { socketID: socket.id, nickname, playerType: "X" };
            room.players.push(player);
            room.turn = player;
            room = await room.save();
            const roomId = room._id.toString();
            socket.join(roomId);
            io.to(roomId).emit("createRoomSuccess", room);
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("joinRoom", async ({ nickname, roomId }) => {
        try {
            if (!roomId.match(/^[0-9a-fA-F]{24}$/)) {
                socket.emit("errorOccurred", "Please enter a valid room ID.");
                return;
            }
            let room = await Room.findById(roomId);
            if (room && room.isJoin) {
                let player = { nickname, socketID: socket.id, playerType: "O" };
                socket.join(roomId);
                room.players.push(player);
                room.isJoin = false;
                room = await room.save();
                io.to(roomId).emit("joinRoomSuccess", room);
                io.to(roomId).emit("updatePlayers", room.players);
                io.to(roomId).emit("updateRoom", room);
            } else {
                socket.emit("errorOccurred", "The game is in progress, try again later.");
            }
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("tap", async ({ index, roomId }) => {
        try {
            let room = await Room.findById(roomId);
            if (!room) return;
            let choice = room.turn.playerType; // x or o
            if (room.turnIndex === 0) {
                room.turn = room.players[1];
                room.turnIndex = 1;
            } else {
                room.turn = room.players[0];
                room.turnIndex = 0;
            }
            room = await room.save();
            io.to(roomId).emit("tapped", { index, choice, room });
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("winner", async ({ winnerSocketId, roomId }) => {
        try {
            let room = await Room.findById(roomId);
            if (!room) return;
            let player = room.players.find(p => p.socketID == winnerSocketId);
            player.points += 1;
            room = await room.save();

            const totalRounds = room.players[0].points + room.players[1].points;
            if (player.points >= 3) {
                io.to(roomId).emit("endGame", player);
            } else if (totalRounds >= room.maxRounds) {
                const otherPlayer = room.players.find(p => p.socketID !== winnerSocketId);
                if (player.points > otherPlayer.points) io.to(roomId).emit("endGame", player);
                else if (otherPlayer.points > player.points) io.to(roomId).emit("endGame", otherPlayer);
                else io.to(roomId).emit("endGame", null);
            } else {
                io.to(roomId).emit("pointIncrease", player);
            }
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("draw", async ({ roomId }) => {
        try {
            let room = await Room.findById(roomId);
            if (!room) return;
            const totalRoundsPlayed = room.players[0].points + room.players[1].points + 1;
            if (totalRoundsPlayed >= room.maxRounds) {
                if (room.players[0].points > room.players[1].points) io.to(roomId).emit("endGame", room.players[0]);
                else if (room.players[1].points > room.players[0].points) io.to(roomId).emit("endGame", room.players[1]);
                else io.to(roomId).emit("endGame", null);
            } else {
                io.to(roomId).emit("drawRound");
            }
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("playerLeft", async ({ roomId, playerId }) => {
        const room = await Room.findById(roomId);
        if (!room) return;
        const opponent = room.players.find(p => p.socketID !== playerId);
        if (opponent) {
            io.to(roomId).emit("gameOver", { winner: opponent.nickname, reason: "opponent_left" });
        }
        await Room.findByIdAndDelete(roomId);
    });

    socket.on("disconnect", () => {
        console.log(`Socket disconnected: ${socket.id}`);
    });
});

// start server
server.listen(port, "0.0.0.0", () => {
    console.log(`Server has started running on ${port}`);
});
