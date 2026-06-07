from pathlib import Path
root = Path('.').resolve()
paths = [
    'lib/widgets/balance_card_new.dart',
    'lib/widgets/budget_progress_indicator.dart',
    'lib/widgets/expense_card.dart',
    'lib/widgets/transaction_item_card.dart',
    'lib/utils/constants.dart',
]
for p in paths:
    q = root / Path(p)
    print(p, 'exists', q.exists(), 'is_file', q.is_file(), 'abs', q)
    if p.startswith('lib/widgets/'):
        rel = Path(p).parent / '../utils/constants.dart'
        print('  resolved relative', (root / rel).resolve(), 'exists', (root / rel).resolve().exists())
