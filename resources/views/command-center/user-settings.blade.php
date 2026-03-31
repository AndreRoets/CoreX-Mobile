@extends('layouts.corex')

@section('corex-content')
<div
    x-data="settingsApp()"
    class="relative min-h-screen"
    style="background: var(--bg);"
>
    {{-- ============================================================
         HEADER
         ============================================================ --}}
    <div class="px-4 py-4 md:px-6">
        <h1 class="text-lg font-bold" style="color: var(--text-primary);">Settings</h1>
        <p class="text-xs mt-0.5" style="color: var(--text-muted);">Notification & calendar preferences</p>
    </div>

    {{-- Agency-controlled banner --}}
    @if($isAgencyControlled)
        <div class="mx-4 md:mx-6 mb-4 px-4 py-3 rounded-md flex items-start gap-3" style="background: #f59e0b15; border: 1px solid #f59e0b30;">
            <svg class="w-5 h-5 shrink-0 mt-0.5" style="color: #f59e0b;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z"/>
            </svg>
            <div>
                <p class="text-sm font-medium" style="color: #f59e0b;">Agency-Controlled Settings</p>
                <p class="text-xs mt-0.5" style="color: var(--text-secondary);">Some settings are managed by your agency and cannot be changed individually.</p>
            </div>
        </div>
    @endif

    {{-- ============================================================
         SETTINGS FORM
         ============================================================ --}}
    <form
        action="{{ route('command-center.user-settings.update') }}"
        method="POST"
        class="px-4 md:px-6 pb-28 md:pb-8 space-y-3 md:max-w-2xl"
    >
        @csrf
        @method('PUT')

        {{-- ======== SECTION: Property Alerts ======== --}}
        <div class="rounded-md overflow-hidden" style="background: var(--surface); border: 1px solid var(--border-default);">
            <button
                type="button"
                @click="toggleSection('property')"
                class="w-full flex items-center justify-between px-4 py-4 text-left"
                style="touch-action: manipulation; min-height: 52px;"
            >
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-md flex items-center justify-center" style="background: #f9731620;">
                        <svg class="w-4 h-4" style="color: #f97316;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                        </svg>
                    </div>
                    <span class="text-sm font-semibold" style="color: var(--text-primary);">Property Alerts</span>
                </div>
                <svg class="w-4 h-4 transition-transform duration-200" :class="openSection === 'property' && 'rotate-180'" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                </svg>
            </button>
            <div x-show="openSection === 'property'" x-transition class="px-4 pb-4 space-y-4" style="border-top: 1px solid var(--border-default);">
                <div class="pt-4">
                    @include('command-center.partials._toggle', [
                        'name' => 'idle_alerts_enabled',
                        'label' => 'Idle property alerts',
                        'description' => 'Get notified when properties have no activity',
                        'checked' => $settings->idle_alerts_enabled ?? true,
                    ])
                </div>
                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Idle threshold (days)</label>
                    <input
                        type="number"
                        name="idle_threshold_days"
                        value="{{ $settings->idle_threshold_days ?? 7 }}"
                        min="1" max="90"
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Alert day</label>
                        <select name="idle_alert_day" class="w-full rounded-md px-4 py-3 text-sm" style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;">
                            @foreach(['monday','tuesday','wednesday','thursday','friday','saturday','sunday'] as $day)
                                <option value="{{ $day }}" {{ ($settings->idle_alert_day ?? 'monday') === $day ? 'selected' : '' }}>{{ ucfirst($day) }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div>
                        <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Alert time</label>
                        <input
                            type="time"
                            name="idle_alert_time"
                            value="{{ $settings->idle_alert_time ?? '08:00' }}"
                            class="w-full rounded-md px-4 py-3 text-sm"
                            style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                        >
                    </div>
                </div>
            </div>
        </div>

        {{-- ======== SECTION: Document Reminders ======== --}}
        <div class="rounded-md overflow-hidden" style="background: var(--surface); border: 1px solid var(--border-default);">
            <button
                type="button"
                @click="toggleSection('documents')"
                class="w-full flex items-center justify-between px-4 py-4 text-left"
                style="touch-action: manipulation; min-height: 52px;"
            >
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-md flex items-center justify-center" style="background: #8b5cf620;">
                        <svg class="w-4 h-4" style="color: #8b5cf6;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                        </svg>
                    </div>
                    <span class="text-sm font-semibold" style="color: var(--text-primary);">Document Reminders</span>
                </div>
                <svg class="w-4 h-4 transition-transform duration-200" :class="openSection === 'documents' && 'rotate-180'" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                </svg>
            </button>
            <div x-show="openSection === 'documents'" x-transition class="px-4 pb-4 space-y-4" style="border-top: 1px solid var(--border-default);">
                <div class="pt-4">
                    @include('command-center.partials._toggle', [
                        'name' => 'doc_reminders_enabled',
                        'label' => 'Document reminders',
                        'description' => 'Remind before document deadlines',
                        'checked' => $settings->doc_reminders_enabled ?? true,
                    ])
                </div>
                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Remind hours before</label>
                    <input
                        type="number"
                        name="doc_reminder_hours_before"
                        value="{{ $settings->doc_reminder_hours_before ?? 24 }}"
                        min="1" max="168"
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>
            </div>
        </div>

        {{-- ======== SECTION: Compliance ======== --}}
        <div class="rounded-md overflow-hidden" style="background: var(--surface); border: 1px solid var(--border-default);">
            <button
                type="button"
                @click="toggleSection('compliance')"
                class="w-full flex items-center justify-between px-4 py-4 text-left"
                style="touch-action: manipulation; min-height: 52px;"
            >
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-md flex items-center justify-center" style="background: #f59e0b20;">
                        <svg class="w-4 h-4" style="color: #f59e0b;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                        </svg>
                    </div>
                    <span class="text-sm font-semibold" style="color: var(--text-primary);">Compliance</span>
                </div>
                <svg class="w-4 h-4 transition-transform duration-200" :class="openSection === 'compliance' && 'rotate-180'" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                </svg>
            </button>
            <div x-show="openSection === 'compliance'" x-transition class="px-4 pb-4 space-y-4" style="border-top: 1px solid var(--border-default);">
                <div class="pt-4">
                    @include('command-center.partials._toggle', [
                        'name' => 'lease_expiry_reminders',
                        'label' => 'Lease expiry reminders',
                        'description' => 'Alert before leases expire',
                        'checked' => $settings->lease_expiry_reminders ?? true,
                    ])
                </div>
                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Remind days before lease expiry</label>
                    <input
                        type="number"
                        name="lease_reminder_days_before"
                        value="{{ $settings->lease_reminder_days_before ?? 30 }}"
                        min="1" max="90"
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>
                <div class="pt-1">
                    @include('command-center.partials._toggle', [
                        'name' => 'fica_reminders',
                        'label' => 'FICA reminders',
                        'description' => 'Remind about FICA compliance requirements',
                        'checked' => $settings->fica_reminders ?? true,
                    ])
                </div>
                <div class="pt-1">
                    @include('command-center.partials._toggle', [
                        'name' => 'ffc_reminders',
                        'label' => 'FFC reminders',
                        'description' => 'Remind about Fidelity Fund Certificate status',
                        'checked' => $settings->ffc_reminders ?? true,
                    ])
                </div>
            </div>
        </div>

        {{-- ======== SECTION: Task & Event Reminders ======== --}}
        <div class="rounded-md overflow-hidden" style="background: var(--surface); border: 1px solid var(--border-default);">
            <button
                type="button"
                @click="toggleSection('reminders')"
                class="w-full flex items-center justify-between px-4 py-4 text-left"
                style="touch-action: manipulation; min-height: 52px;"
            >
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-md flex items-center justify-center" style="background: #0ea5e920;">
                        <svg class="w-4 h-4" style="color: #0ea5e9;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
                        </svg>
                    </div>
                    <span class="text-sm font-semibold" style="color: var(--text-primary);">Task & Event Reminders</span>
                </div>
                <svg class="w-4 h-4 transition-transform duration-200" :class="openSection === 'reminders' && 'rotate-180'" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                </svg>
            </button>
            <div x-show="openSection === 'reminders'" x-transition class="px-4 pb-4 space-y-4" style="border-top: 1px solid var(--border-default);">
                <div class="pt-4">
                    @include('command-center.partials._toggle', [
                        'name' => 'task_due_reminders',
                        'label' => 'Task due reminders',
                        'description' => 'Remind before tasks are due',
                        'checked' => $settings->task_due_reminders ?? true,
                    ])
                </div>
                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Task reminder hours before</label>
                    <input
                        type="number"
                        name="task_reminder_hours_before"
                        value="{{ $settings->task_reminder_hours_before ?? 24 }}"
                        min="1" max="168"
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>
                <div>
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Event reminder hours before</label>
                    <input
                        type="number"
                        name="event_reminder_hours_before"
                        value="{{ $settings->event_reminder_hours_before ?? 2 }}"
                        min="1" max="168"
                        class="w-full rounded-md px-4 py-3 text-sm"
                        style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                    >
                </div>
            </div>
        </div>

        {{-- ======== SECTION: Calendar ======== --}}
        <div class="rounded-md overflow-hidden" style="background: var(--surface); border: 1px solid var(--border-default);">
            <button
                type="button"
                @click="toggleSection('calendar')"
                class="w-full flex items-center justify-between px-4 py-4 text-left"
                style="touch-action: manipulation; min-height: 52px;"
            >
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-md flex items-center justify-center" style="background: #3b82f620;">
                        <svg class="w-4 h-4" style="color: #3b82f6;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                        </svg>
                    </div>
                    <span class="text-sm font-semibold" style="color: var(--text-primary);">Calendar</span>
                </div>
                <svg class="w-4 h-4 transition-transform duration-200" :class="openSection === 'calendar' && 'rotate-180'" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                </svg>
            </button>
            <div x-show="openSection === 'calendar'" x-transition class="px-4 pb-4 space-y-4" style="border-top: 1px solid var(--border-default);">
                <div class="pt-4">
                    <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Default calendar view</label>
                    <select name="default_calendar_view" class="w-full rounded-md px-4 py-3 text-sm" style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;">
                        <option value="month" {{ ($settings->default_calendar_view ?? 'month') === 'month' ? 'selected' : '' }}>Month</option>
                        <option value="agenda" {{ ($settings->default_calendar_view ?? 'month') === 'agenda' ? 'selected' : '' }}>Agenda</option>
                    </select>
                </div>
                <div class="pt-1">
                    @include('command-center.partials._toggle', [
                        'name' => 'weekend_visible',
                        'label' => 'Show weekends',
                        'description' => 'Display Saturday and Sunday on calendar',
                        'checked' => $settings->weekend_visible ?? true,
                    ])
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Working hours start</label>
                        <input
                            type="time"
                            name="working_hours_start"
                            value="{{ $settings->working_hours_start ?? '08:00' }}"
                            class="w-full rounded-md px-4 py-3 text-sm"
                            style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                        >
                    </div>
                    <div>
                        <label class="text-xs font-medium mb-2 block" style="color: var(--text-secondary);">Working hours end</label>
                        <input
                            type="time"
                            name="working_hours_end"
                            value="{{ $settings->working_hours_end ?? '17:00' }}"
                            class="w-full rounded-md px-4 py-3 text-sm"
                            style="background: var(--surface-2); color: var(--text-primary); border: 1px solid var(--border-default); min-height: 48px;"
                        >
                    </div>
                </div>
            </div>
        </div>

        {{-- ======== SECTION: Notifications ======== --}}
        <div class="rounded-md overflow-hidden" style="background: var(--surface); border: 1px solid var(--border-default);">
            <button
                type="button"
                @click="toggleSection('notifications')"
                class="w-full flex items-center justify-between px-4 py-4 text-left"
                style="touch-action: manipulation; min-height: 52px;"
            >
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-md flex items-center justify-center" style="background: #22c55e20;">
                        <svg class="w-4 h-4" style="color: #22c55e;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                        </svg>
                    </div>
                    <span class="text-sm font-semibold" style="color: var(--text-primary);">Notifications</span>
                </div>
                <svg class="w-4 h-4 transition-transform duration-200" :class="openSection === 'notifications' && 'rotate-180'" style="color: var(--text-muted);" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                </svg>
            </button>
            <div x-show="openSection === 'notifications'" x-transition class="px-4 pb-4 space-y-4" style="border-top: 1px solid var(--border-default);">
                <div class="pt-4">
                    @include('command-center.partials._toggle', [
                        'name' => 'notify_in_app',
                        'label' => 'In-app notifications',
                        'description' => 'Show notifications within CoreX OS',
                        'checked' => $settings->notify_in_app ?? true,
                    ])
                </div>
                <div class="pt-1">
                    @include('command-center.partials._toggle', [
                        'name' => 'notify_email',
                        'label' => 'Email notifications',
                        'description' => 'Receive notifications via email',
                        'checked' => $settings->notify_email ?? true,
                    ])
                </div>
            </div>
        </div>

        {{-- Desktop save button --}}
        <div class="hidden md:block pt-4">
            <button
                type="submit"
                class="px-8 py-3 rounded-md text-sm font-semibold text-white transition-colors"
                style="background: var(--brand-button); min-height: 48px; touch-action: manipulation;"
            >
                Save Settings
            </button>
        </div>
    </form>

    {{-- ============================================================
         STICKY SAVE BUTTON (mobile)
         ============================================================ --}}
    <div
        class="fixed bottom-0 left-0 right-0 z-50 md:hidden px-4 py-3"
        style="
            background: rgba(5,5,5,0.9);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border-top: 1px solid var(--border-default);
            padding-bottom: env(safe-area-inset-bottom, 0px);
        "
    >
        <button
            type="submit"
            form="settings-form"
            onclick="this.closest('div').previousElementSibling.querySelector('form').submit()"
            class="w-full py-3.5 rounded-md text-sm font-semibold text-white transition-colors"
            style="background: var(--brand-button); min-height: 48px; touch-action: manipulation;"
        >
            Save Settings
        </button>
    </div>
</div>

<script>
function settingsApp() {
    return {
        openSection: null,

        toggleSection(section) {
            this.openSection = this.openSection === section ? null : section;
        }
    };
}
</script>
@endsection
