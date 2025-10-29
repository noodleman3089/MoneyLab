# --- SYMBOLS AND FETCH SETTINGS ---

# Set to True to fetch all NASDAQ symbols automatically.
# Set to False to use the manual STOCK_SYMBOLS list below.
FETCH_ALL_NASDAQ = False

# A curated list of popular US stocks (approx. 100)
STOCK_SYMBOLS = [
    'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'NVDA', 'META', 'TSLA', 'BRK-B', 'LLY', 'V',
    'JPM', 'WMT', 'XOM', 'UNH', 'MA', 'JNJ', 'PG', 'ORCL', 'HD', 'CVX',
    'MRK', 'COST', 'ABBV', 'BAC', 'PEP', 'KO', 'ADBE', 'TMO', 'CRM', 'MCD',
    'PFE', 'ACN', 'NFLX', 'LIN', 'AMD', 'WFC', 'CSCO', 'DIS', 'AVGO', 'DHR',
    'TXN', 'VER', 'ABT', 'CAT', 'PM', 'INTC', 'CMCSA', 'AMGN', 'IBM', 'NOW',
    'UBER', 'COP', 'QCOM', 'SPGI', 'RTX', 'GS', 'UNP', 'INTU', 'PLTR', 'MU',
    'T', 'AXP', 'MDT', 'HON', 'SBUX', 'BKNG', 'LMT', 'BLK', 'UPS', 'BA',
    'ELV', 'GE', 'DE', 'AMAT', 'C', 'SYK', 'ISRG', 'VRTX', 'GSK', 'MDLZ',
    'REGN', 'PGR', 'ADI', 'TJX', 'CI', 'ETN', 'SLB', 'PYPL', 'LRCX', 'ZTS',
    'SO', 'DUK', 'MO', 'CVS', 'TGT', 'LOW', 'MS', 'WBA', 'PNC', 'COF'
]

# A curated list of popular US ETFs (approx. 20)
FUND_SYMBOLS = [
    'SPY', 'IVV', 'VOO', 'VTI', 'QQQ', 'VEA', 'VUG', 'IEFA', 'VTV', 'BND',
    'GLD', 'AGG', 'IWF', 'IEMG', 'VGT', 'VXUS', 'VWO', 'DIA', 'SCHD', 'XLK'
]

# Interval in seconds. 1 hour (3600 seconds) is a good balance for this list size.
FETCH_INTERVAL_SECONDS = 3600

# A curated list of popular Thai stocks (approx. 50)
THAI_STOCK_SYMBOLS = [
    'AOT', 'DELTA', 'PTT', 'ADVANC', 'GULF', 'CPALL', 'KTB', 'SCB', 'KBANK', 'BDMS',
    'SCC', 'CPN', 'TRUE', 'PTTEP', 'BBL', 'CRC', 'EA', 'MINT', 'TTB', 'HMPRO',
    'CPAXT', 'IVL', 'BJC', 'KTC', 'BGRIM', 'TOP', 'OR', 'CENTEL', 'LH', 'GPSC',
    'SCGP', 'TISCO', 'MTC', 'AWC', 'RATCH', 'SAWAD', 'COM7', 'CBG', 'OSP', 'WHA',
    'GLOBAL', 'BAM', 'BH', 'TIDLOR', 'ITC', 'DOHOME', 'PLANB', 'TU', 'M', 'KCE'
]
