import time
from app.services import yfinance_service
from app.models import investment_model

def run_sync_cycle(conn, stock_symbols, fund_symbols, thai_symbols):
    """
    Orchestrates a single data synchronization cycle for US stocks, funds, and Thai stocks.

    Args:
        conn: An active MySQL database connection.
        stock_symbols (list): A list of US stock symbols to process.
        fund_symbols (list): A list of fund symbols to process.
        thai_symbols (list): A list of Thai stock symbols to process (without .BK suffix).
    """
    # --- Process US Stocks ---
    print(f"Processing {len(stock_symbols)} US stock symbols...")
    for symbol in stock_symbols:
        ticker_info = yfinance_service.fetch_ticker_info(symbol)
        if ticker_info:
            investment_model.save_stock_data(conn, ticker_info)
        time.sleep(1)  # API delay

    # --- Process Funds ---
    print(f"\nProcessing {len(fund_symbols)} fund symbols...")
    for symbol in fund_symbols:
        ticker_info = yfinance_service.fetch_ticker_info(symbol)
        if ticker_info:
            investment_model.save_fund_data(conn, ticker_info)
        time.sleep(1)  # API delay

    # --- Process Thai Stocks ---
    print(f"\nProcessing {len(thai_symbols)} Thai stock symbols...")
    for symbol in thai_symbols:
        # Add .BK suffix for yfinance
        th_ticker = f"{symbol}.BK"
        ticker_info = yfinance_service.fetch_ticker_info(th_ticker)
        if ticker_info:
            investment_model.save_th_stock_data(conn, ticker_info)
        time.sleep(1)  # API delay

    # --- Commit all transactions for this cycle ---
    conn.commit()
    print("\nSync cycle completed and data committed.")
