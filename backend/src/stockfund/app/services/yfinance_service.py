import yfinance as yf

def fetch_ticker_info(symbol):
    """
    Fetches all available information for a given ticker symbol using yfinance.

    Args:
        symbol (str): The stock/fund symbol to fetch.

    Returns:
        dict: A dictionary containing the ticker information, or None if an error occurs.
    """
    try:
        ticker = yf.Ticker(symbol)
        info = ticker.info
        # The info dict can be empty for delisted or invalid tickers
        if not info or 'symbol' not in info:
            print(f"Warning: No data found for symbol '{symbol}'. It may be invalid or delisted.")
            return None
        return info
    except Exception as e:
        print(f"Error fetching data for {symbol} from yfinance: {e}")
        return None
