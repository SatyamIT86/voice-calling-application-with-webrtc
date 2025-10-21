const express = require('express');
const app = express();
const server = require('http').createServer(app);
const io = require('socket.io')(server, {
  cors: { origin: "*" }
});

const users = new Map();

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('register', (userId) => {
    users.set(userId, socket.id);
    socket.userId = userId;
  });

  socket.on('call', (data) => {
    const targetSocketId = users.get(data.to);
    if (targetSocketId) {
      io.to(targetSocketId).emit('incoming-call', {
        from: socket.userId,
        offer: data.offer,
        callerName: data.callerName
      });
    }
  });

  socket.on('answer', (data) => {
    const targetSocketId = users.get(data.to);
    if (targetSocketId) {
      io.to(targetSocketId).emit('call-answered', {
        answer: data.answer
      });
    }
  });

  socket.on('ice-candidate', (data) => {
    const targetSocketId = users.get(data.to);
    if (targetSocketId) {
      io.to(targetSocketId).emit('ice-candidate', {
        candidate: data.candidate
      });
    }
  });

  socket.on('end-call', (data) => {
    const targetSocketId = users.get(data.to);
    if (targetSocketId) {
      io.to(targetSocketId).emit('call-ended');
    }
  });

  socket.on('disconnect', () => {
    if (socket.userId) {
      users.delete(socket.userId);
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
});
