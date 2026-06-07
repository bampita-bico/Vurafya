-- Migration 078: Guild/Clan System
-- Plus can join guilds, Pro can create guilds
-- Condition-focused guilds with tailored challenges

-- ============================================================================
-- GUILDS
-- ============================================================================

CREATE TABLE IF NOT EXISTS guilds (
    id INTEGER PRIMARY KEY,
    guild_name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT,
    guild_tag VARCHAR(10),
        -- Short tag like [CKD], [DM], [FIT]
    leader_id INTEGER NOT NULL REFERENCES users(id),
    co_leader_id INTEGER REFERENCES users(id),
    guild_level INTEGER DEFAULT 1,
    guild_xp INTEGER DEFAULT 0,
    max_members INTEGER DEFAULT 30,
    current_member_count INTEGER DEFAULT 1,
    condition_focus VARCHAR(60),
        -- CKD, Diabetes, Hypertension, General, Mixed
    min_subscription_tier_join INTEGER DEFAULT 2,
        -- 2=Plus can join
    min_subscription_tier_create INTEGER DEFAULT 3,
        -- 3=Pro can create
    icon VARCHAR(60),
    banner_color VARCHAR(10),
    is_public BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- GUILD MEMBERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS guild_members (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    guild_id INTEGER NOT NULL REFERENCES guilds(id),
    rank_id INTEGER NOT NULL DEFAULT 1,
    contribution_xp INTEGER DEFAULT 0,
    challenges_completed INTEGER DEFAULT 0,
    weekly_activity_score REAL DEFAULT 0,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id, guild_id)
);

-- ============================================================================
-- GUILD RANKS
-- ============================================================================

CREATE TABLE IF NOT EXISTS guild_ranks (
    id INTEGER PRIMARY KEY,
    rank_name VARCHAR(40) NOT NULL UNIQUE,
    rank_level INTEGER NOT NULL UNIQUE,
    permissions TEXT,
        -- JSON: ["invite","kick","promote","start_challenge","manage_settings"]
    min_contribution_xp INTEGER DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- GUILD CHALLENGES
-- ============================================================================

CREATE TABLE IF NOT EXISTS guild_challenges (
    id INTEGER PRIMARY KEY,
    guild_id INTEGER NOT NULL REFERENCES guilds(id),
    challenge_name VARCHAR(120) NOT NULL,
    description TEXT,
    challenge_type VARCHAR(40) NOT NULL,
        -- collective_meals, collective_steps, nutrient_target, med_adherence, boss_kills
    target_value REAL NOT NULL,
    current_value REAL DEFAULT 0,
    condition_focus VARCHAR(60),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
        -- pending, active, completed, failed, expired
    xp_reward_per_member INTEGER DEFAULT 100,
    ap_reward_per_member INTEGER DEFAULT 25,
    guild_xp_reward INTEGER DEFAULT 500,
    min_participants INTEGER DEFAULT 5,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- ============================================================================
-- GUILD CHALLENGE PROGRESS (per-member contribution)
-- ============================================================================

CREATE TABLE IF NOT EXISTS guild_challenge_progress (
    id INTEGER PRIMARY KEY,
    challenge_id INTEGER NOT NULL REFERENCES guild_challenges(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    contribution_value REAL DEFAULT 0,
    contribution_rank INTEGER,
    last_contribution_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(challenge_id, user_id)
);

-- ============================================================================
-- GUILD CHAT MESSAGES
-- ============================================================================

CREATE TABLE IF NOT EXISTS guild_chat_messages (
    id INTEGER PRIMARY KEY,
    guild_id INTEGER NOT NULL REFERENCES guilds(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    message_text TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text',
        -- text, system, achievement, challenge_update
    is_pinned BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- GUILD LEVEL REQUIREMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS guild_level_requirements (
    id INTEGER PRIMARY KEY,
    guild_level INTEGER NOT NULL UNIQUE,
    xp_required INTEGER NOT NULL,
    max_members_unlock INTEGER NOT NULL,
    perk_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- GUILD PERKS (unlocked at guild levels)
-- ============================================================================

CREATE TABLE IF NOT EXISTS guild_perks (
    id INTEGER PRIMARY KEY,
    perk_name VARCHAR(80) NOT NULL,
    perk_type VARCHAR(40) NOT NULL,
        -- xp_bonus, cosmetic_unlock, challenge_slot, member_cap, exclusive_quest
    perk_value REAL,
    required_guild_level INTEGER NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SEED: GUILD RANKS
-- ============================================================================

INSERT OR IGNORE INTO guild_ranks (id, rank_name, rank_level, permissions, min_contribution_xp, description) VALUES
(1, 'Initiate', 1, '["chat"]', 0, 'New guild member. Can participate in chat and challenges.'),
(2, 'Member', 2, '["chat","react"]', 500, 'Active member. Proven contribution to the guild.'),
(3, 'Officer', 3, '["chat","react","invite","start_challenge"]', 2000, 'Trusted member. Can invite others and start challenges.'),
(4, 'Elder', 4, '["chat","react","invite","kick","start_challenge","promote"]', 5000, 'Senior leader. Can manage members and challenges.'),
(5, 'Leader', 5, '["chat","react","invite","kick","start_challenge","promote","manage_settings","disband"]', 0, 'Guild founder/leader. Full control.');

-- ============================================================================
-- SEED: GUILD LEVEL REQUIREMENTS
-- ============================================================================

INSERT OR IGNORE INTO guild_level_requirements (guild_level, xp_required, max_members_unlock, perk_description) VALUES
(1, 0, 30, 'Starting guild: 30 members max'),
(2, 5000, 35, 'Guild banner customization'),
(3, 15000, 40, '+5% XP bonus for all members'),
(4, 30000, 40, 'Unlock weekly guild challenges'),
(5, 50000, 45, '+10% XP bonus for all members'),
(6, 80000, 45, 'Exclusive guild cosmetics'),
(7, 120000, 50, 'Guild boss encounters'),
(8, 170000, 50, '+15% XP bonus for all members'),
(9, 230000, 55, 'Exclusive guild quest line'),
(10, 300000, 60, 'Guild Hall + all perks maxed');

-- ============================================================================
-- SEED: GUILD PERKS
-- ============================================================================

INSERT OR IGNORE INTO guild_perks (perk_name, perk_type, perk_value, required_guild_level, description) VALUES
('Guild Banner', 'cosmetic_unlock', NULL, 2, 'Customize guild banner and colors'),
('XP Boost I', 'xp_bonus', 5.0, 3, '+5% XP for all guild members'),
('Weekly Challenge', 'challenge_slot', 1, 4, 'Unlock 1 weekly guild challenge slot'),
('XP Boost II', 'xp_bonus', 10.0, 5, '+10% XP for all guild members'),
('Guild Cosmetics', 'cosmetic_unlock', NULL, 6, 'Exclusive guild-themed cosmetics'),
('Guild Boss Access', 'exclusive_quest', NULL, 7, 'Guild-only boss encounters'),
('XP Boost III', 'xp_bonus', 15.0, 8, '+15% XP for all guild members'),
('Guild Quest Line', 'exclusive_quest', NULL, 9, 'Exclusive multi-chapter guild quest'),
('Guild Hall', 'cosmetic_unlock', NULL, 10, 'Virtual guild hall + trophy room');

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'guilds' AS tbl, COUNT(*) AS rows FROM guilds
UNION ALL
SELECT 'guild_ranks', COUNT(*) FROM guild_ranks
UNION ALL
SELECT 'guild_level_requirements', COUNT(*) FROM guild_level_requirements
UNION ALL
SELECT 'guild_perks', COUNT(*) FROM guild_perks
UNION ALL
SELECT 'guild_members', COUNT(*) FROM guild_members
UNION ALL
SELECT 'guild_challenges', COUNT(*) FROM guild_challenges
UNION ALL
SELECT 'guild_chat_messages', COUNT(*) FROM guild_chat_messages;
