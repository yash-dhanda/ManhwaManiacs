from __future__ import annotations

from fastapi import APIRouter, Depends

from routes.ai import router as ai_router
from routes.app_distribution import router as app_distribution_router
from routes.app_media import router as app_media_router
from routes.auth import router as auth_router
from routes.backup import router as backup_router
from routes.circle import router as circle_router
from routes.discover import router as discover_router
from routes.home import router as home_router
from routes.onboarding import router as onboarding_router
from routes.library import router as library_router
from routes.ocr import router as ocr_router
from routes.profiles import router as profiles_router
from routes.reader import router as reader_router
from routes.series import router as series_router
from routes.sources import router as sources_router
from routes.settings import router as settings_router
from routes.system import router as system_router
from routes.updates import router as updates_router
from services.auth_service import enforce_authentication

# Every route on the API requires a valid session except the public allowlist
# defined in enforce_authentication (health/landing, APK distribution, and the
# login/register entry points). This is the single global authentication gate.
api_router = APIRouter(dependencies=[Depends(enforce_authentication)])
api_router.include_router(system_router)
api_router.include_router(app_distribution_router)
api_router.include_router(app_media_router)
api_router.include_router(auth_router)
api_router.include_router(circle_router)
api_router.include_router(backup_router)
api_router.include_router(settings_router)
api_router.include_router(library_router)
api_router.include_router(home_router)
api_router.include_router(ai_router)
api_router.include_router(discover_router)
api_router.include_router(onboarding_router)
api_router.include_router(reader_router)
api_router.include_router(series_router)
api_router.include_router(sources_router)
api_router.include_router(ocr_router)
api_router.include_router(updates_router)
api_router.include_router(profiles_router)
