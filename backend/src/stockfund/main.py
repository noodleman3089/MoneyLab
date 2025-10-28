import time
import sys
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# --- Pre-run check for required libraries ---
try:
    import mysql.connector
    import yfinance
except ImportError as e:
    print(f"Error: Missing required library. ({e.name})")
    print(f"Please install it using: pip install {e.name}")
    sys.exit(1)

# --- Local Imports ---
from config.database import DB_CONFIG
from config.settings import STOCK_SYMBOLS, FUND_SYMBOLS, THAI_STOCK_SYMBOLS, FETCH_INTERVAL_SECONDS, FETCH_ALL_NASDAQ
from app.controllers import sync_controller
from app.services import ticker_service

SEPARATOR = "=" * 80

def main():
    """
    Main application loop.
    - Determines the list of stocks to fetch.
    - Establishes a database connection.
    - Triggers the synchronization cycle.
    - Waits for the specified interval.
    """
    
    # --- Determine which stock symbols to use ---
    stocks_to_process = []
    if FETCH_ALL_NASDAQ:
        stocks_to_process = ticker_service.get_nasdaq_tickers()
        if not stocks_to_process: # Fallback if download fails
            print("Fallback: Using manual US stock list from settings.")
            stocks_to_process = STOCK_SYMBOLS
    else:
        print("Using manual US stock list from settings.")
        stocks_to_process = STOCK_SYMBOLS

    # --- Main application loop ---
    while True:
        print(f"\n{SEPARATOR}")
        print(f"Starting data fetch cycle at {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Processing {len(stocks_to_process)} US stocks, {len(FUND_SYMBOLS)} funds, and {len(THAI_STOCK_SYMBOLS)} Thai stocks this cycle.")
        print(SEPARATOR)

        conn = None
        try:
            # 1. Establish connection to the database
            conn = mysql.connector.connect(**DB_CONFIG)
            print("Database connection established successfully.")

            # 2. Run the synchronization cycle via the controller
            sync_controller.run_sync_cycle(conn, stocks_to_process, FUND_SYMBOLS, THAI_STOCK_SYMBOLS)

        except mysql.connector.Error as err:
            print(f"Fatal Error: Database connection failed: {err}")
            # If DB is down, wait a shorter time before retrying
            print("Waiting 5 minutes before retrying connection...")
            time.sleep(300)
            continue # Skip the main interval wait and try to reconnect
        
        except Exception as e:
            print(f"An unexpected error occurred in the main loop: {e}")

        finally:
            if conn and conn.is_connected():
                conn.close()
                print("\nDatabase connection closed.")

        print(f"\n{SEPARATOR}")
        print(f"Cycle complete. Waiting for {FETCH_INTERVAL_SECONDS / 3600:.1f} hours...")
        time.sleep(FETCH_INTERVAL_SECONDS)

if __name__ == "__main__":
    main()
