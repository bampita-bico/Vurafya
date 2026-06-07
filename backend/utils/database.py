import re
from collections.abc import Mapping, Sequence

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from backend.config import settings

# For PostgreSQL, we use asyncpg
# DATABASE_URL should be in format: postgresql+asyncpg://user:pass@host:port/db
DATABASE_URL = settings.DATABASE_URL
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class AsyncResultCursor:
    """Small aiosqlite-shaped cursor around a SQLAlchemy result."""

    def __init__(self, result):
        self._result = result
        self.lastrowid = None
        self.rowcount = getattr(result, "rowcount", -1)
        try:
            returned = result.mappings().all()
        except Exception:
            returned = []
        self._rows = [dict(row) for row in returned]
        if self._rows and "id" in self._rows[0]:
            self.lastrowid = self._rows[0]["id"]

    async def fetchone(self):
        if not self._rows:
            return None
        return self._rows.pop(0)

    async def fetchall(self):
        rows = self._rows
        self._rows = []
        return rows


class DatabaseCompatSession:
    """Compatibility layer for legacy routes while the app completes Postgres migration."""

    def __init__(self, session: AsyncSession):
        self.session = session

    @staticmethod
    def _normalize_sql(sql: str) -> str:
        normalized = sql
        replacements = {
            "datetime('now')": "NOW()",
            "date('now', '+100 years')": "(CURRENT_DATE + INTERVAL '100 years')",
            "date('now','start of month')": "date_trunc('month', CURRENT_DATE)::date",
            "date('now')": "CURRENT_DATE",
            "strftime('%Y','now')": "EXTRACT(YEAR FROM CURRENT_DATE)::int",
            "INSERT OR IGNORE": "INSERT",
            "AUTOINCREMENT": "",
        }
        for old, new in replacements.items():
            normalized = normalized.replace(old, new)
        return normalized

    @staticmethod
    def _bind_positional(sql: str, params: Sequence | None) -> tuple[str, dict]:
        values = list(params or [])
        bound: dict[str, object] = {}

        def repl(_match):
            key = f"p{len(bound)}"
            if len(bound) >= len(values):
                raise ValueError("SQL statement has more placeholders than bound parameters")
            bound[key] = values[len(bound)]
            return f":{key}"

        statement = re.sub(r"\?", repl, sql)
        if len(bound) != len(values):
            raise ValueError("SQL statement has more bound parameters than placeholders")
        return statement, bound

    @staticmethod
    def _should_return_id(sql: str) -> bool:
        head = sql.lstrip().lower()
        return head.startswith("insert into") and " returning " not in head

    async def execute(self, sql, params=None):
        if not isinstance(sql, str):
            result = await self.session.execute(sql, params or {})
            return AsyncResultCursor(result)

        statement = self._normalize_sql(sql)
        if isinstance(params, Mapping):
            bound = dict(params)
        else:
            statement, bound = self._bind_positional(statement, params)

        if self._should_return_id(statement):
            statement = f"{statement} RETURNING id"

        try:
            result = await self.session.execute(text(statement), bound)
        except Exception:
            if statement.rstrip().lower().endswith(" returning id"):
                fallback = statement.rsplit(" RETURNING id", 1)[0]
                result = await self.session.execute(text(fallback), bound)
            else:
                raise
        return AsyncResultCursor(result)

    async def commit(self):
        await self.session.commit()

    async def rollback(self):
        await self.session.rollback()

    async def close(self):
        await self.session.close()

    async def scalar(self, sql, params=None):
        cursor = await self.execute(sql, params)
        row = await cursor.fetchone()
        if not row:
            return None
        return next(iter(row.values()))

    def raw_session(self) -> AsyncSession:
        return self.session

async def get_db():
    async with AsyncSessionLocal() as session:
        db = DatabaseCompatSession(session)
        try:
            yield db
        finally:
            await session.close()

async def check_db() -> dict:
    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute(text("SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'"))
            count = result.scalar()
            return {"connected": True, "tables": count, "type": "postgresql"}
    except Exception as e:
        return {"connected": False, "error": str(e)}

def get_db_path():
    # Keep for compatibility with scripts that still expect a path
    return settings.DB_PATH
