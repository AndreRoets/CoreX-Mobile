{{--
    Priority Pills Selector Component
    Props:
      $name     - form input name (default: 'priority')
      $selected - pre-selected value (default: 'normal')
      $options  - override options array (default: low/normal/high/critical)
--}}
@props([
    'name' => 'priority',
    'selected' => 'normal',
    'options' => null,
])

@php
    $pillOptions = $options ?? [
        'low'      => ['label' => 'Low',      'color' => '#6b7280'],
        'normal'   => ['label' => 'Normal',    'color' => '#0ea5e9'],
        'high'     => ['label' => 'High',      'color' => '#f59e0b'],
        'critical' => ['label' => 'Critical',  'color' => '#ef4444'],
    ];
@endphp

<div
    x-data="{ selected: '{{ $selected }}' }"
    class="flex gap-2 overflow-x-auto pb-1"
    style="-webkit-overflow-scrolling: touch;"
>
    <input type="hidden" name="{{ $name }}" :value="selected">

    @foreach($pillOptions as $value => $opt)
        <button
            type="button"
            @click="selected = '{{ $value }}'"
            class="px-4 py-2 rounded-md text-xs font-medium whitespace-nowrap transition-all duration-200 shrink-0"
            :class="selected === '{{ $value }}'
                ? 'ring-1 ring-offset-1 ring-offset-transparent'
                : 'opacity-60 hover:opacity-80'"
            :style="selected === '{{ $value }}'
                ? 'background: {{ $opt['color'] }}20; color: {{ $opt['color'] }}; ring-color: {{ $opt['color'] }};'
                : 'background: var(--surface-2); color: var(--text-secondary);'"
            style="min-height: 44px; touch-action: manipulation;"
        >
            {{ $opt['label'] }}
        </button>
    @endforeach
</div>
