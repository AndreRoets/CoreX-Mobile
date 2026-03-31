{{--
    iOS-style Toggle Switch
    Props:
      $name        - form input name
      $label       - display label
      $description - optional description text
      $checked     - boolean, initial state
      $disabled    - boolean, grayed out
--}}
@props([
    'name' => '',
    'label' => '',
    'description' => null,
    'checked' => false,
    'disabled' => false,
])

<label class="flex items-center justify-between gap-4 {{ $disabled ? 'opacity-50 pointer-events-none' : 'cursor-pointer' }}" style="touch-action: manipulation; min-height: 44px;">
    <div class="flex-1 min-w-0">
        <p class="text-sm font-medium" style="color: var(--text-primary);">{{ $label }}</p>
        @if($description)
            <p class="text-xs mt-0.5" style="color: var(--text-muted);">{{ $description }}</p>
        @endif
    </div>
    <div class="relative shrink-0">
        <input type="hidden" name="{{ $name }}" value="0">
        <input
            type="checkbox"
            name="{{ $name }}"
            value="1"
            {{ $checked ? 'checked' : '' }}
            {{ $disabled ? 'disabled' : '' }}
            class="sr-only peer"
        >
        <div
            class="w-[52px] h-[32px] rounded-full transition-colors duration-300 ease-in-out peer-checked:bg-[#0ea5e9]"
            style="background: var(--surface-2);"
        ></div>
        <div
            class="absolute left-[3px] top-[3px] w-[26px] h-[26px] bg-white rounded-full shadow-sm transition-transform duration-300 ease-in-out peer-checked:translate-x-[20px]"
        ></div>
    </div>
</label>
