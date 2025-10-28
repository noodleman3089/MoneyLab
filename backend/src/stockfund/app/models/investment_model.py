from datetime import datetime

def save_stock_data(conn, info):
    """Saves or updates stock data in the 'stocks' table."""
    if not conn or not info:
        return False

    cursor = conn.cursor()
    symbol = info.get('symbol')

    data = {
        'symbol': symbol,
        'long_name': info.get('longName'),
        'current_price': info.get('currentPrice') or info.get('regularMarketPrice'),
        'market_cap': info.get('marketCap'),
        'sector': info.get('sector'),
        'industry': info.get('industry'),
        'last_updated': datetime.now()
    }

    sql = """
        INSERT INTO stocks (
            symbol, long_name, current_price, market_cap, sector, industry, last_updated
        )
        VALUES (%(symbol)s, %(long_name)s, %(current_price)s, %(market_cap)s, %(sector)s, %(industry)s, %(last_updated)s)
        ON DUPLICATE KEY UPDATE
            long_name = VALUES(long_name),
            current_price = VALUES(current_price),
            market_cap = VALUES(market_cap),
            sector = VALUES(sector),
            industry = VALUES(industry),
            last_updated = VALUES(last_updated),
            updated_at = CURRENT_TIMESTAMP;
    """

    try:
        cursor.execute(sql, data)
        print(f"[STOCK] Successfully saved/updated data for: {symbol}")
        return True
    except Exception as e:
        print(f"[STOCK] Database error for symbol {symbol}: {e}")
        return False
    finally:
        cursor.close()

def save_fund_data(conn, info):
    """Saves or updates fund data in the 'funds' table."""
    if not conn or not info:
        return False

    cursor = conn.cursor()
    symbol = info.get('symbol')

    data = {
        'symbol': symbol,
        'long_name': info.get('longName'),
        'current_price': info.get('currentPrice') or info.get('regularMarketPrice'),
        'category': info.get('category'),
        'total_assets': info.get('totalAssets'),
        'nav_price': info.get('navPrice'),
        'ytd_return': info.get('ytdReturn'),
        'last_updated': datetime.now()
    }

    sql = """
        INSERT INTO funds (
            symbol, long_name, current_price, category, total_assets, nav_price, ytd_return, last_updated
        )
        VALUES (%(symbol)s, %(long_name)s, %(current_price)s, %(category)s, %(total_assets)s, %(nav_price)s, %(ytd_return)s, %(last_updated)s)
        ON DUPLICATE KEY UPDATE
            long_name = VALUES(long_name),
            current_price = VALUES(current_price),
            category = VALUES(category),
            total_assets = VALUES(total_assets),
            nav_price = VALUES(nav_price),
            ytd_return = VALUES(ytd_return),
            last_updated = VALUES(last_updated),
            updated_at = CURRENT_TIMESTAMP;
    """

    try:
        cursor.execute(sql, data)
        print(f"[FUND] Successfully saved/updated data for: {symbol}")
        return True
    except Exception as e:
        print(f"[FUND] Database error for symbol {symbol}: {e}")
        return False
    finally:
        cursor.close()

def save_th_stock_data(conn, info):
    """Saves or updates Thai stock data in the 'stocksTH' table."""
    if not conn or not info:
        return False

    cursor = conn.cursor()
    # The symbol from yfinance will include .BK, which we want to save.
    symbol = info.get('symbol')

    data = {
        'symbol': symbol,
        'long_name': info.get('longName'),
        'current_price': info.get('currentPrice') or info.get('regularMarketPrice'),
        'market_cap': info.get('marketCap'),
        'sector': info.get('sector'),
        'industry': info.get('industry'),
        'last_updated': datetime.now()
    }

    sql = """
        INSERT INTO stocksTH (
            symbol, long_name, current_price, market_cap, sector, industry, last_updated
        )
        VALUES (%(symbol)s, %(long_name)s, %(current_price)s, %(market_cap)s, %(sector)s, %(industry)s, %(last_updated)s)
        ON DUPLICATE KEY UPDATE
            long_name = VALUES(long_name),
            current_price = VALUES(current_price),
            market_cap = VALUES(market_cap),
            sector = VALUES(sector),
            industry = VALUES(industry),
            last_updated = VALUES(last_updated),
            updated_at = CURRENT_TIMESTAMP;
    """

    try:
        cursor.execute(sql, data)
        print(f"[STOCK-TH] Successfully saved/updated data for: {symbol}")
        return True
    except Exception as e:
        print(f"[STOCK-TH] Database error for symbol {symbol}: {e}")
        return False
    finally:
        cursor.close()