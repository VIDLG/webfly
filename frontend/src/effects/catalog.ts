import { defineCatalog } from '@json-render/core'
import { schema } from '@json-render/react/schema'
import { z } from 'zod'

/**
 * json-render catalog for LED effect UIs.
 *
 * Defines the component vocabulary and props schemas that ui.json specs can use.
 * These are the guardrails: only components declared here are renderable.
 */
export const effectCatalog = defineCatalog(schema, {
  components: {
    // ── Layout ────────────────────────────────────────────────

    Stack: {
      props: z.object({
        direction: z.enum(['vertical', 'horizontal']).nullable().optional(),
        gap: z.enum(['sm', 'md', 'lg']).nullable().optional(),
      }),
      slots: ['default'],
      description: 'Flex layout container. direction: vertical (default) or horizontal.',
    },

    Card: {
      props: z.object({
        title: z.string().nullable().optional(),
      }),
      slots: ['default'],
      description: 'Bordered card container with optional title.',
    },

    // ── Controls ──────────────────────────────────────────────

    CupertinoSlider: {
      props: z.object({
        label: z.string(),
        min: z.number(),
        max: z.number(),
        step: z.number().nullable().optional(),
        value: z.number().nullable().optional(),
        unit: z.string().nullable().optional(),
        minLabel: z.string().nullable().optional(),
        maxLabel: z.string().nullable().optional(),
        accentColor: z.string().nullable().optional(),
      }),
      description: 'Flutter Cupertino slider. Use { $bindState } on value for two-way binding.',
    },

    ColorHSV: {
      props: z.object({
        label: z.string(),
        hue: z.number().nullable().optional(),
        saturation: z.number().nullable().optional(),
        brightness: z.number().nullable().optional(),
        accentColor: z.string().nullable().optional(),
      }),
      description:
        'HSV color picker with 3 sliders + color swatch preview. Use { $bindState } on hue, saturation, brightness.',
    },

    // ── Display ───────────────────────────────────────────────

    Text: {
      props: z.object({
        text: z.string(),
        variant: z.enum(['label', 'value', 'hint']).nullable().optional(),
      }),
      description: 'Text element.',
    },
  },
  actions: {},
})
