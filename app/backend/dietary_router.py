from fastapi import APIRouter
from dietary_restriction_service import DietaryRestrictionService

router = APIRouter(prefix="/diet")

service = DietaryRestrictionService()


@router.get("/conditions")
def get_conditions():
    return service.get_all_conditions()


@router.get("/{condition}/allowed")
def allowed(condition: str):
    return service.get_allowed(condition)


@router.get("/{condition}/avoid")
def avoid(condition: str):
    return service.get_avoid(condition)


@router.get("/{condition}/weekly")
def weekly(condition: str):
    return service.generate_weekly_plan(condition)