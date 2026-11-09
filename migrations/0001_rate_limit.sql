-- Rate limiting του /api/chat: μία γραμμή για κάθε επιτρεπόμενη ερώτηση.
-- ip_hash = SHA-256(RATE_SALT + IP), ποτέ η ίδια η IP. ts = Date.now() σε ms.
-- Οι γραμμές παλιότερες των 2 ημερών σβήνονται από το chat.js.
CREATE TABLE IF NOT EXISTS hits (
  ip_hash TEXT NOT NULL,
  ts INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_hits_ip_ts ON hits (ip_hash, ts);
CREATE INDEX IF NOT EXISTS idx_hits_ts ON hits (ts);
