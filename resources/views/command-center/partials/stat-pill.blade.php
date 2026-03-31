{{--
    Stat Pill Component
    Props:
      $value  - number or string
      $label  - text label
      $color  - optional dot/accent color (hex)
      $active - boolean, highlight state
--}}
@props([
    'value' => '0',
    'label' => '',
    'color' => null,
    'active' => false,
])

<div
    class="flex items-center gap-2 px-4 py-2.5 rounded-md whitespace-nowrap shrink-0 transition-colors duration-200 select-none"
    style="
        background: {{ $active ? 'var(--brand-default)' : 'var(--surface)' }};
        border: 1px solid {{ $active ? 'var(--brand-button)' : 'var(--border-default)' }};
        touch-action: manipulation;
        min-height: 44px;
    "
>
    @if($color)
        <span class="w-2 h-2 rounded-full shrink-0" style="background: {{ $color }};"></span>
    @endif
    <span class="text-sm font-semibold" style="color: var(--text-primary);">{{ $value }}</span>
    <span class="text-xs" style="color: var(--text-secondary);">{{ $label }}</span>
</div>
