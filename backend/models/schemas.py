from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import date, datetime


# ============================================================================
# AUTH
# ============================================================================

class RegisterRequest(BaseModel):
    email: str
    username: str
    password: str = Field(min_length=6)

class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class RefreshRequest(BaseModel):
    refresh_token: str


# ============================================================================
# USERS
# ============================================================================

class ProfileUpdate(BaseModel):
    age: Optional[int] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    activity_level: Optional[str] = None
    health_goal: Optional[str] = None
    country_code: Optional[str] = None

class HealthDeclarationRequest(BaseModel):
    condition_id: int
    stage: Optional[str] = None
    severity: Optional[str] = "moderate"
    diagnosed_date: Optional[str] = None
    declaration_source: str = "self_reported"


# ============================================================================
# SUBSCRIPTIONS
# ============================================================================

class FeatureCheckResponse(BaseModel):
    allowed: bool
    limit: Optional[int] = None
    feature_key: str
    required_tier: int
    user_tier: int

class UpgradeRequest(BaseModel):
    plan_id: int
    billing_cycle: str = "monthly"
    payment_method: str = "mobile_money"


# ============================================================================
# NUTRITION
# ============================================================================

class MealComponentInput(BaseModel):
    food_id: int
    quantity_grams: float = Field(gt=0, le=5000)
    meal_component_type: str = "main"

class MealCreateRequest(BaseModel):
    meal_type: str = Field(default="lunch", pattern="^(breakfast|lunch|dinner|snack)$")
    meal_date: Optional[str] = None
    components: list[MealComponentInput] = Field(min_length=1, max_length=50)
    notes: Optional[str] = None


# ============================================================================
# GAME
# ============================================================================

class ChooseClassRequest(BaseModel):
    class_id: int

class PaginationParams(BaseModel):
    offset: int = 0
    limit: int = 20


# ============================================================================
# PHARMACY
# ============================================================================

class MedicationScheduleCreate(BaseModel):
    medication_id: int
    schedule_type: str = "daily"
    times_per_day: int = 1
    scheduled_times: Optional[str] = None       # JSON string e.g. '["08:00","20:00"]'
    dose_amount: Optional[str] = None
    meal_relation: str = "with_meal"
    start_date: str
    end_date: Optional[str] = None
    reminder_enabled: bool = True
    reminder_minutes_before: int = 15
    notes: Optional[str] = None

class AdherenceLogCreate(BaseModel):
    medication_id: int
    schedule_id: Optional[int] = None
    scheduled_at: Optional[str] = None
    taken_at: Optional[str] = None
    status: str = "taken"                       # taken | skipped | late
    dose_taken: Optional[str] = None
    skip_reason: Optional[str] = None
    side_effects: Optional[str] = None
    notes: Optional[str] = None


# ============================================================================
# BIOMETRICS
# ============================================================================

class GlucoseLogCreate(BaseModel):
    glucose_mg_dl: float
    measurement_context: str = "fasting"        # fasting | post_meal | random | bedtime
    recorded_at: Optional[str] = None
    meal_id: Optional[int] = None
    hours_since_meal: Optional[float] = None
    insulin_dose_units: Optional[float] = None
    medication_taken: Optional[str] = None
    physical_activity: Optional[str] = None
    symptoms: Optional[str] = None
    notes: Optional[str] = None

class VitalsLogCreate(BaseModel):
    recorded_at: Optional[str] = None
    temperature_c: Optional[float] = None
    pulse_bpm: Optional[int] = None
    respiratory_rate: Optional[int] = None
    oxygen_saturation_pct: Optional[float] = None
    blood_pressure_systolic: Optional[int] = None
    blood_pressure_diastolic: Optional[int] = None
    measurement_location: str = "arm"
    measured_by: str = "self"
    notes: Optional[str] = None

class CreatinineLogCreate(BaseModel):
    creatinine_mg_dl: float
    egfr_ml_min: Optional[float] = None
    egfr_formula: str = "CKD-EPI"
    measured_at: Optional[str] = None
    ckd_stage: Optional[str] = None
    measurement_context: str = "routine"
    lab_facility_id: Optional[int] = None
    notes: Optional[str] = None
    bun_mg_dl: Optional[float] = None
    urine_albumin_mg: Optional[float] = None

class PotassiumLogCreate(BaseModel):
    potassium_value: float
    unit: str = "mEq/L"
    measured_at: Optional[str] = None
    measurement_context: str = "routine"
    lab_facility_id: Optional[int] = None
    notes: Optional[str] = None

class PhosphorusLogCreate(BaseModel):
    phosphorus_mg_dl: float
    measured_at: Optional[str] = None
    measurement_context: str = "routine"
    lab_facility_id: Optional[int] = None
    notes: Optional[str] = None
    calcium_mg_dl: Optional[float] = None
    pth_pg_ml: Optional[float] = None
    vitamin_d_ng_ml: Optional[float] = None


# ============================================================================
# MEDICAL
# ============================================================================

class ConsultationBookRequest(BaseModel):
    doctor_profile_id: int
    consultation_type: str = "telehealth"       # telehealth | in_person
    scheduled_at: str
    duration_minutes: int = 30
    is_priority: bool = False
    payment_method: str = "mobile_money"
    chief_complaint: Optional[str] = None
    notes: Optional[str] = None

class CancelBookingRequest(BaseModel):
    reason: str

class LabOrderCreate(BaseModel):
    test_ids: list[int]
    consultation_id: Optional[int] = None
    facility_id: Optional[int] = None
    priority: str = "routine"                   # routine | urgent | stat
    fasting_status: str = "not_required"
    notes: Optional[str] = None


# ============================================================================
# GAME EXTRAS
# ============================================================================

class BossDamageRequest(BaseModel):
    damage: int = Field(ge=1, le=10000)

class CreateGuildRequest(BaseModel):
    guild_name: str = Field(min_length=3, max_length=80)
    description: Optional[str] = None
    guild_tag: Optional[str] = Field(default=None, max_length=10)
    condition_focus: Optional[str] = None
    is_public: bool = True

class CraftRecipeRequest(BaseModel):
    recipe_id: int
    food_ids: list[int] = []

class AdoptPetRequest(BaseModel):
    species_id: int
    pet_name: Optional[str] = None

class PetCareRequest(BaseModel):
    action: str                                 # feed | play | heal


# ============================================================================
# TRUST & KYC
# ============================================================================

class SubmitKycRequest(BaseModel):
    kyc_tier: int = Field(ge=0, le=3)
    has_verified_phone: bool = False
    has_provided_full_name: bool = False
    has_provided_dob: bool = False
    has_national_id: bool = False
    national_id_verified: bool = False
    has_proof_of_address: bool = False
    has_tax_id: bool = False
    has_bank_verification: bool = False
    documents: list[str] = []


# ============================================================================
# NOTIFICATIONS
# ============================================================================

class UpdateNotificationPrefsRequest(BaseModel):
    meal_reminders: Optional[bool] = None
    challenge_updates: Optional[bool] = None
    medical_alerts: Optional[bool] = None


# ============================================================================
# ADMIN
# ============================================================================

class ResolveFraudAlertRequest(BaseModel):
    review_status: str = "reviewed"          # reviewed | false_positive | confirmed_fraud
    notes: Optional[str] = None
    resolution_action: str = "no_action"     # no_action | warn_user | suspend_user | ban_user


# ============================================================================
# PREVENTIVE MEDICINE
# ============================================================================

class NutrientTargetRequest(BaseModel):
    nutrient_id: int
    target_value: float = Field(gt=0)

class LogRiskRequest(BaseModel):
    condition_name: str
    risk_score: float = Field(ge=0.0, le=1.0)
    risk_category: str                        # low | moderate | high | critical
    risk_factors: list[str] = []
    protective_factors: list[str] = []
    recommendations: list[str] = []
    confidence_score: float = 0.8


# ============================================================================
# SOCIAL
# ============================================================================

class FriendResponseRequest(BaseModel):
    accept: bool

class SendMessageRequest(BaseModel):
    receiver_id: int
    message_text: str = Field(min_length=1, max_length=2000)

class SendGuildMessageRequest(BaseModel):
    message_text: str = Field(min_length=1, max_length=1000)


# ============================================================================
# SOCIAL GOOD
# ============================================================================

class RegisterVulnerableRequest(BaseModel):
    is_elderly: bool = False
    is_disabled: bool = False
    is_child: bool = False
    is_pregnant: bool = False
    is_low_income: bool = False
    is_orphan: bool = False
    is_refugee: bool = False
    is_ckd_patient: bool = False
    verification_method: str = "self_declared"
    documents: list[str] = []


# ============================================================================
# PUSH NOTIFICATIONS / FCM
# ============================================================================

class RegisterFcmTokenRequest(BaseModel):
    fcm_token: str
    device_id: str
    platform: str = "android"          # android | ios | web
    app_version: Optional[str] = None

class SendTestPushRequest(BaseModel):
    title: str
    body: str


# ============================================================================
# OTP
# ============================================================================

class RequestOtpRequest(BaseModel):
    phone_number: str
    purpose: str = "transaction_verification"
    transaction_id: Optional[int] = None
    transaction_type: Optional[str] = None
    transaction_amount_ugx: Optional[float] = None

class VerifyOtpRequest(BaseModel):
    otp_id: int
    otp_code: str = Field(min_length=4, max_length=8)


# ============================================================================
# OFFLINE SYNC
# ============================================================================

class QueueOfflineTransactionRequest(BaseModel):
    device_id: str
    transaction_type: str
    transaction_data: dict
    created_offline_at: Optional[str] = None
    priority: int = 5
    is_critical: bool = False

class SyncOfflineRequest(BaseModel):
    device_id: str
