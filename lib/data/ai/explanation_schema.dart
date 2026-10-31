/// JSON Schema of the answer for [promptVersion] `prompt_v1`. The same shape is
/// read by `parseExplanation`; a test builds a value from this schema and
/// parses it, so the two cannot drift apart.
const explanationSchemaV1 = <String, Object?>{
  'type': 'object',
  'properties': {
    'components': {
      'type': 'array',
      'description': 'Parts of the character and what each contributes.',
      'items': {
        'type': 'object',
        'properties': {
          'part': {'type': 'string'},
          'role': {'type': 'string'},
        },
        'required': ['part', 'role'],
      },
    },
    'mnemonic': {
      'type': 'string',
      'description': 'One or two sentences to remember the character.',
    },
    'examples': {
      'type': 'array',
      'description': 'Two common words that contain the character.',
      'items': {
        'type': 'object',
        'properties': {
          'word': {'type': 'string'},
          'reading': {
            'type': 'string',
            'description': 'Reading of the whole word.',
          },
          'meaning': {'type': 'string'},
        },
        'required': ['word', 'reading', 'meaning'],
      },
    },
    'usage_note': {
      'type': 'string',
      'description': 'Only when Chinese and Japanese usage differ.',
    },
  },
  'required': ['components', 'mnemonic', 'examples'],
};
