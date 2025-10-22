// server/server.js
const express = require('express');
const app = express();
const server = require('http').createServer(app);
const io = require('socket.io')(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  },
  transports: ['websocket', 'polling']
});

const users = new Map();

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'running', 
    activeUsers: users.size,
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

io.on('connection', (socket) => {
  console.log('✅ User connected:', socket.id);

  socket.on('register', (userId) => {
    users.set(userId, socket.id);
    socket.userId = userId;
    console.log(`📝 User registered: ${userId} (${socket.id})`);
    console.log(`👥 Total active users: ${users.size}`);
  });

  socket.on('call', (data) => {
    console.log(`📞 Call from ${socket.userId} to ${data.to}`);
    const targetSocketId = users.get(data.to);
    
    if (targetSocketId) {
      console.log(`✅ Forwarding call to ${targetSocketId}`);
      io.to(targetSocketId).emit('incoming-call', {
        from: socket.userId,
        offer: data.offer,
        callerName: data.callerName
      });
    } else {
      console.log(`❌ Target user ${data.to} not found`);
      socket.emit('call-error', { message: 'User not available' });
    }
  });

  socket.on('answer', (data) => {
    console.log(`✅ Call answered from ${socket.userId} to ${data.to}`);
    const targetSocketId = users.get(data.to);
    
    if (targetSocketId) {
      io.to(targetSocketId).emit('call-answered', {
        answer: data.answer
      });
    }
  });

  socket.on('ice-candidate', (data) => {
    console.log(`🧊 ICE candidate from ${socket.userId} to ${data.to}`);
    const targetSocketId = users.get(data.to);
    
    if (targetSocketId) {
      io.to(targetSocketId).emit('ice-candidate', {
        candidate: data.candidate
      });
    }
  });

  socket.on('end-call', (data) => {
    console.log(`📴 Call ended from ${socket.userId} to ${data.to}`);
    const targetSocketId = users.get(data.to);
    
    if (targetSocketId) {
      io.to(targetSocketId).emit('call-ended');
    }
  });

  socket.on('disconnect', () => {
    if (socket.userId) {
      users.delete(socket.userId);
      console.log(`❌ User disconnected: ${socket.userId}`);
      console.log(`👥 Total active users: ${users.size}`);
    }
  });

  socket.on('error', (error) => {
    console.error('❌ Socket error:', error);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`
  ╔════════════════════════════════════════╗
  ║   🚀 Signaling Server Running          ║
  ║   📡 Port: ${PORT}                     ║
  ║   🌐 Ready to accept connections       ║
  ╚════════════════════════════════════════╝
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});