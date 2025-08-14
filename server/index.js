// importing the modules
const express = require("express");
const http = require("http");
const mongoose = require("mongoose");

const app = express();
const port = process.env.PORT || 3000;
var server = http.createServer(app);
const Room = require('./models/room');
var io = require("socket.io")(server);

// client -> middlware -> server (to maybe manipulate the data)
// middleware
app.use(express.json());


const DB = "mongodb+srv://sidharth:sidharth@cluster0.9smtxx1.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";

io.on("connection", (socket) => {
    console.log("socket connected!");
    socket.on("createRoom", async ({ nickname }) => {
        console.log(nickname);
        try {
            // room is created
            let room = new Room();
            let player = {
                socketID: socket.id,
                nickname,
                playerType: "X",
            };
            room.players.push(player);
            room.turn = player;
            room = await room.save();
            console.log(room);
            const roomId = room._id.toString();

            socket.join(roomId);
            // io -> send data to everyone
            // socket -> sending data to yourself
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

            if (room.isJoin) {
                let player = {
                    nickname,
                    socketID: socket.id,
                    playerType: "O",
                };
                socket.join(roomId);
                room.players.push(player);
                room.isJoin = false;
                room = await room.save();
                io.to(roomId).emit("joinRoomSuccess", room);
                io.to(roomId).emit("updatePlayers", room.players);
                io.to(roomId).emit("updateRoom", room);
            } else {
                socket.emit(
                    "errorOccurred",
                    "The game is in progress, try again later."
                );
            }
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("tap", async ({ index, roomId }) => {
        try {
            let room = await Room.findById(roomId);

            let choice = room.turn.playerType; // x or o
            if (room.turnIndex == 0) {
                room.turn = room.players[1];
                room.turnIndex = 1;
            } else {
                room.turn = room.players[0];
                room.turnIndex = 0;
            }
            room = await room.save();
            io.to(roomId).emit("tapped", {
                index,
                choice,
                room,
            });
        } catch (e) {
            console.log(e);
        }
    });

    socket.on("winner", async ({ winnerSocketId, roomId }) => {
        try {
            let room = await Room.findById(roomId);
            let player = room.players.find(
                (playerr) => playerr.socketID == winnerSocketId
            );
            player.points += 1;
            room = await room.save();

            const totalRounds = room.players[0].points + room.players[1].points;
            console.log(`Player points: ${player.points}, Total rounds: ${totalRounds}, Max rounds: ${room.maxRounds}`);
            if (player.points >= 3) {
                io.to(roomId).emit("endGame", player);
            } else if (totalRounds >= room.maxRounds) {
                // Game ends due to round limit, determine winner by points
                const otherPlayer = room.players.find(p => p.socketID !== winnerSocketId);
                if (player.points > otherPlayer.points) {
                    io.to(roomId).emit("endGame", player);
                } else if (otherPlayer.points > player.points) {
                    io.to(roomId).emit("endGame", otherPlayer);
                } else {
                    io.to(roomId).emit("endGame", null); // True tie
                }
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

            // Check if this draw ends the game (both players have played max rounds)
            const totalRoundsPlayed = room.players[0].points + room.players[1].points + 1; // +1 for current draw

            if (totalRoundsPlayed >= room.maxRounds) {
                // Game ends, determine winner by points or declare tie
                if (room.players[0].points > room.players[1].points) {
                    io.to(roomId).emit("endGame", room.players[0]);
                } else if (room.players[1].points > room.players[0].points) {
                    io.to(roomId).emit("endGame", room.players[1]);
                } else {
                    // True tie - send a tie message
                    io.to(roomId).emit("endGame", null);
                }
            } else {
                io.to(roomId).emit("drawRound"); // Just a round draw
            }
        } catch (e) {
            console.log(e);
        }
    });


    socket.on('playerLeft', async ({ roomId, playerId }) => {
        const room = await Room.findById(roomId);
        if (!room) return;

        // Find opponent
        const opponent = room.players.find(p => p.socketID !== playerId);
        if (opponent) {
            io.to(roomId).emit('gameOver', {
                winner: opponent.nickname,
                reason: 'opponent_left'
            });
        }

        // Optional: delete room from DB
        await Room.findByIdAndDelete(roomId);
    });


});

mongoose.connect(DB).then(() => {
    console.log('Database Connection successful');
}).catch((e) => {
    console.log(e);
});

server.listen(port, '0.0.0.0', () => {
    console.log(`Server has started running on ${port}`);
})