from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    LargeBinary,
    ForeignKey,
)
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime

Base = declarative_base()


class User(Base):
    """User model for authentication and account management."""

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    desired_name = Column(String, nullable=True)  # Preferred classroom name
    phone = Column(String, nullable=True)  # Optional phone number
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    # Password reset fields
    password_reset_token = Column(String, nullable=True, unique=True)
    password_reset_expires = Column(DateTime, nullable=True)
    password_reset_requested_at = Column(DateTime, nullable=True)

    # Role-based access control
    role = Column(
        String, default="pending", nullable=False
    )  # pending, teacher, paraeducator, admin

    # Approval workflow for pending users
    is_approved = Column(Boolean, default=False, nullable=False)
    approved_at = Column(DateTime, nullable=True)
    approved_by_id = Column(Integer, nullable=True)  # Admin user ID who approved
    approval_notes = Column(String, nullable=True)

    # Rejection workflow
    is_rejected = Column(Boolean, default=False, nullable=False)
    rejected_at = Column(DateTime, nullable=True)
    rejected_by_id = Column(Integer, nullable=True)  # Admin user ID who rejected
    rejection_reason = Column(String, nullable=True)

    # Registration date (set when approved by admin/super admin)
    registered_date = Column(
        DateTime, nullable=True
    )  # UTC datetime when user was registered/approved

    # Profile image (stored as binary data)
    profile_image = Column(
        LargeBinary, nullable=True
    )  # User's profile image in binary format

    # Timezone preference
    timezone = Column(
        String, nullable=True
    )  # User's preferred timezone (e.g., 'America/Los_Angeles')


class Student(Base):
    """Student model for managing student records."""

    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    age = Column(Integer, nullable=True)  # Student age
    grade = Column(Integer, nullable=True)  # Grade level (1-12)
    grade_level = Column(
        String, nullable=True
    )  # Grade level as string (e.g., "K", "1st", "2nd")
    classroom = Column(
        String, nullable=True
    )  # Classroom/room assignment (deprecated, use gened_teacher)
    gened_teacher = Column(String, nullable=True)  # General education teacher name
    sped_teacher = Column(String, nullable=True)  # Special education teacher name
    gender = Column(String, nullable=True)  # Student gender identity (optional)
    notes = Column(String, nullable=True)  # Optional free-text notes about the student
    school_id = Column(String, nullable=True)  # School identifier
    email = Column(String, nullable=True)
    parent_names = Column(
        String, nullable=True
    )  # Comma-separated parent/guardian names
    parent_contact_phone = Column(String, nullable=True)  # Primary contact phone
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    # Student profile image (stored as binary data)
    student_image = Column(
        LargeBinary, nullable=True
    )  # Student's profile image in binary format


class Behavior(Base):
    """Behavior model for tracking student behavior incidents."""

    __tablename__ = "behaviors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    category = Column(
        String(50), nullable=False, index=True
    )  # 'antecedent_motivation' or 'problem_behavior'
    type = Column(
        String(50), nullable=False, index=True
    )  # For problem_behavior: 'major', 'minor', 'general'; For antecedent_motivation: 'get', 'avoid'
    short_description = Column(String(500), nullable=False)
    long_description = Column(
        String, nullable=True
    )  # Rich text with Unicode (emojis, links)
    frequency_12_months = Column(
        Integer, default=0, nullable=False
    )  # Frequency in past 12 months
    frequency_all_time = Column(
        Integer, default=0, nullable=False
    )  # Frequency for all time
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
    created_by_id = Column(Integer, nullable=False)  # User ID who created this behavior
    updated_by_id = Column(
        Integer, nullable=True
    )  # User ID who last updated this behavior
    updated_by_name = Column(String(255), nullable=True)  # Last updater's display name

    def __repr__(self) -> str:
        return f"<Behavior(id={self.id}, name={self.name}, category={self.category}, type={self.type})>"


class AssignedStudentBehavior(Base):
    """Assigned Student Behavior model for linking students to their assigned behaviors."""

    __tablename__ = "assigned_student_behaviors"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    behavior_id = Column(
        Integer, ForeignKey("behaviors.id"), nullable=False, index=True
    )
    assigned_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    assigned_by_id = Column(Integer, nullable=False, index=True)
    notes = Column(String, nullable=True)

    # Relationships
    student = relationship("Student", backref="assigned_behaviors")
    behavior = relationship("Behavior", backref="student_assignments")

    def __repr__(self) -> str:
        return f"<AssignedStudentBehavior(id={self.id}, student_id={self.student_id}, behavior_id={self.behavior_id})>"


class Strategy(Base):
    """Strategy model for managing behavior intervention strategies."""

    __tablename__ = "strategies"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True, unique=True)
    category = Column(
        String(50), nullable=True, index=True
    )  # Optional categorization (e.g., 'behavioral', 'academic', 'social')
    type = Column(String(50), nullable=True, index=True)  # Optional type classification
    short_description = Column(String(500), nullable=False, default="")
    long_description = Column(
        String, nullable=True
    )  # Rich text with Unicode (emojis, links)
    frequency_12_months = Column(
        Integer, default=0, nullable=False
    )  # Usage frequency in past 12 months
    frequency_all_time = Column(
        Integer, default=0, nullable=False
    )  # Usage frequency for all time
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
    created_by_id = Column(Integer, nullable=False)
    updated_by_id = Column(Integer, nullable=True)
    created_by_name = Column(String(255), nullable=True)  # Creator's display name
    updated_by_name = Column(String(255), nullable=True)  # Last updater's display name

    def __repr__(self) -> str:
        return f"<Strategy(id={self.id}, name={self.name}, category={self.category})>"


class AssignedStudentStrategy(Base):
    """Assigned Student Strategy model for linking students to their assigned strategies."""

    __tablename__ = "assigned_student_strategies"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    strategy_id = Column(
        Integer, ForeignKey("strategies.id"), nullable=False, index=True
    )
    assigned_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    assigned_by_id = Column(Integer, nullable=False, index=True)
    notes = Column(String, nullable=True)

    # Relationships
    student = relationship("Student", backref="assigned_strategies")
    strategy = relationship("Strategy", backref="student_assignments")

    def __repr__(self) -> str:
        return f"<AssignedStudentStrategy(id={self.id}, student_id={self.student_id}, strategy_id={self.strategy_id})>"


class Support(Base):
    """Support model for managing student support resources."""

    __tablename__ = "supports"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True, unique=True)
    category = Column(
        String(50), nullable=True, index=True
    )  # Optional categorization (e.g., 'environmental', 'personnel', 'technological')
    type = Column(String(50), nullable=True, index=True)  # Optional type classification
    short_description = Column(String(500), nullable=False, default="")
    long_description = Column(
        String, nullable=True
    )  # Rich text with Unicode (emojis, links)
    frequency_12_months = Column(
        Integer, default=0, nullable=False
    )  # Usage frequency in past 12 months
    frequency_all_time = Column(
        Integer, default=0, nullable=False
    )  # Usage frequency for all time
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
    created_by_id = Column(Integer, nullable=False)
    updated_by_id = Column(Integer, nullable=True)
    created_by_name = Column(String(255), nullable=True)  # Creator's display name
    updated_by_name = Column(String(255), nullable=True)  # Last updater's display name

    def __repr__(self) -> str:
        return f"<Support(id={self.id}, name={self.name}, category={self.category})>"


class Accommodation(Base):
    """Accommodation model for managing student accommodations."""

    __tablename__ = "accommodations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True, unique=True)
    category = Column(
        String(50), nullable=True, index=True
    )  # Optional categorization (e.g., 'instructional', 'assessment', 'environmental')
    type = Column(String(50), nullable=True, index=True)  # Optional type classification
    short_description = Column(String(500), nullable=False, default="")
    long_description = Column(
        String, nullable=True
    )  # Rich text with Unicode (emojis, links)
    frequency_12_months = Column(
        Integer, default=0, nullable=False
    )  # Usage frequency in past 12 months
    frequency_all_time = Column(
        Integer, default=0, nullable=False
    )  # Usage frequency for all time
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
    created_by_id = Column(Integer, nullable=False)
    updated_by_id = Column(Integer, nullable=True)
    created_by_name = Column(String(255), nullable=True)  # Creator's display name
    updated_by_name = Column(String(255), nullable=True)  # Last updater's display name

    def __repr__(self) -> str:
        return (
            f"<Accommodation(id={self.id}, name={self.name}, category={self.category})>"
        )


class AssignedStudentSupport(Base):
    """Assigned Student Support model for linking students to their assigned supports."""

    __tablename__ = "assigned_student_supports"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    support_id = Column(Integer, ForeignKey("supports.id"), nullable=False, index=True)
    assigned_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    assigned_by_id = Column(Integer, nullable=False, index=True)
    notes = Column(String, nullable=True)

    # Relationships
    student = relationship("Student", backref="assigned_supports")
    support = relationship("Support", backref="student_assignments")

    def __repr__(self) -> str:
        return f"<AssignedStudentSupport(id={self.id}, student_id={self.student_id}, support_id={self.support_id})>"


class AssignedStudentAccommodation(Base):
    """Assigned Student Accommodation model for linking students to their assigned accommodations."""

    __tablename__ = "assigned_student_accommodations"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    accommodation_id = Column(
        Integer, ForeignKey("accommodations.id"), nullable=False, index=True
    )
    assigned_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    assigned_by_id = Column(Integer, nullable=False, index=True)
    notes = Column(String, nullable=True)

    # Relationships
    student = relationship("Student", backref="assigned_accommodations")
    accommodation = relationship("Accommodation", backref="student_assignments")

    def __repr__(self) -> str:
        return f"<AssignedStudentAccommodation(id={self.id}, student_id={self.student_id}, accommodation_id={self.accommodation_id})>"


class StudentTrackingCounter(Base):
    """Student Tracking Counter model for daily behavior occurrence counts."""

    __tablename__ = "student_tracking_counters"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    behavior_id = Column(
        Integer, ForeignKey("behaviors.id"), nullable=False, index=True
    )
    tracking_date = Column(DateTime, nullable=False, index=True)  # Date being tracked
    behavior_category = Column(
        String(50), nullable=False, index=True
    )  # 'antecedent_motivation' or 'problem_behavior'
    behavior_subtype = Column(
        String(50), nullable=False, index=True
    )  # 'get', 'avoid' for antecedent; 'major', 'minor', 'general' for problem
    count = Column(
        Integer, default=0, nullable=False
    )  # Number of occurrences for this day
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
    updated_by_id = Column(Integer, nullable=False)  # User who last modified counter
    updated_by_name = Column(String(255), nullable=True)  # Display name of last updater

    # Relationships
    student = relationship("Student", backref="tracking_counters")
    behavior = relationship("Behavior", backref="tracking_counters")

    def __repr__(self) -> str:
        return f"<StudentTrackingCounter(id={self.id}, student_id={self.student_id}, behavior_id={self.behavior_id}, count={self.count})>"


class StudentTrackingLog(Base):
    """Student Tracking Log model for logging individual behavior occurrences."""

    __tablename__ = "student_tracking_logs"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    behavior_id = Column(
        Integer, ForeignKey("behaviors.id"), nullable=False, index=True
    )
    counter_id = Column(
        Integer,
        ForeignKey("student_tracking_counters.id"),
        nullable=False,
        index=True,
    )
    behavior_category = Column(
        String(50), nullable=False, index=True
    )  # 'antecedent_motivation' or 'problem_behavior'
    behavior_subtype = Column(
        String(50), nullable=False, index=True
    )  # 'get', 'avoid' for antecedent; 'major', 'minor', 'general' for problem
    behavior_name = Column(String(255), nullable=False)  # Behavior name at time of log
    action_type = Column(
        String(20), nullable=False, index=True
    )  # 'increment' or 'decrement' (undo)
    occurred_at = Column(
        DateTime, default=datetime.utcnow, nullable=False, index=True
    )  # When behavior occurred
    logged_at = Column(
        DateTime, default=datetime.utcnow, nullable=False
    )  # When log entry was created
    logged_by_id = Column(Integer, nullable=False, index=True)  # User who logged this
    logged_by_name = Column(String(255), nullable=True)  # Display name of logger
    notes = Column(String, nullable=True)  # Optional notes about this occurrence

    # Relationships
    student = relationship("Student", backref="tracking_logs")
    behavior = relationship("Behavior", backref="tracking_logs")
    counter = relationship("StudentTrackingCounter", backref="tracking_logs")

    def __repr__(self) -> str:
        return f"<StudentTrackingLog(id={self.id}, student_id={self.student_id}, behavior_id={self.behavior_id}, action_type={self.action_type})>"
