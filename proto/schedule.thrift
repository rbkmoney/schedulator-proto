include "base.thrift"
include "domain.thrift"
include "payout_processing.thrift"

namespace java com.rbkmoney.damsel.schedule
namespace erlang com.rbkmoney.damsel.schedule

typedef list<Event> Events
typedef string URL
typedef base.ID ScheduleID

typedef base.Opaque GenericServiceExecutionContext

struct RegisterJobRequest {
    // путь до сервиса, который будет исполнять Job
    1: required URL executor_service_path
    2: required Schedule schedule
    3: required GenericServiceExecutionContext context
}

struct ExecuteJobRequest {
    1: required ScheduledJobContext scheduled_job_context
    2: required GenericServiceExecutionContext service_execution_context
}

union Schedule {
    1: DominantBasedSchedule dominant_schedule
}

struct DominantBasedSchedule {
    1: required domain.BusinessScheduleRef business_schedule_ref
    2: required domain.CalendarRef calendar_ref
    3: optional domain.DataRevision revision
}

struct ScheduledJobContext {
    1: required base.Timestamp next_fire_time
    2: required base.Timestamp prev_fire_time
    3: required base.Timestamp next_cron_time
}

union ContextValidationResponse {
    1: required list<string> errors
}

struct DeregisterJob {}

exception NoLastEvent {}
exception EventNotFound {}
exception ScheduleNotFound {}
exception ScheduleAlreadyExists {}
exception BadContextProvided {
    1: required ContextValidationResponse validation_response
}

struct ScheduleJobRegistered {
    1: required ScheduleID schedule_id
    2: required URL executor_service_path
    3: required GenericServiceExecutionContext context
    4: required Schedule schedule
}

struct ScheduleJobExecuted {
    1: required ExecuteJobRequest request
    2: required GenericServiceExecutionContext response
}

struct ScheduleContextValidated {
    1: required GenericServiceExecutionContext request
    2: required ContextValidationResponse response
}

struct ScheduleJobDeregistered {}

/**
 * Диапазон для выборки событий
 */
struct EventRange {
    1: optional base.EventID after
    2: required i32 limit
}

/**
 * Один из возможных вариантов события, порождённого расписания
 */
union ScheduleChange {
    1: ScheduleJobRegistered        schedule_job_registered
    2: ScheduleContextValidated     schedule_context_validated
    3: ScheduleJobExecuted          schedule_job_executed
    4: ScheduleJobDeregistered      schedule_job_deregistered
}

/**
 * Один из возможных вариантов содержания события
 */
struct EventPayload {
    /* Набор изменений, порождённых расписанием */
    1: list<ScheduleChange> schedule_changes
}

/**
 * Событие, атомарный фрагмент истории бизнес-объекта, например расписания
 */
struct Event {
    1: required base.EventID id
    2: required base.Timestamp created_at
    3: required ScheduleID source
    4: required EventPayload payload
}

/**
* Интерфейс сервиса регистрирующего и высчитывающего расписания выполнений
**/
service Schedulator {

    void RegisterJob(1: ScheduleID schedule_id, 2: RegisterJobRequest request)
        throws (1: ScheduleAlreadyExists schedule_already_exists_ex, 2: BadContextProvided bad_context_provided_ex)

    void DeregisterJob(1: ScheduleID schedule_id)
        throws (1: ScheduleNotFound ex)
}

/**
* Интерфейс для сервисов, выполняющих Job-ы по расписанию
**/
service ScheduledJobExecutor {

    /** метод вызывается при попытке зарегистрировать Job */
    ContextValidationResponse ValidateExecutionContext(1: GenericServiceExecutionContext context)

    GenericServiceExecutionContext ExecuteJob(1: ExecuteJobRequest request)

}
