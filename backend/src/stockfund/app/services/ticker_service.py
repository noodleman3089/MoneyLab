import urllib.request
import io

def get_nasdaq_tickers():
    """
    Downloads the full list of NASDAQ-listed and other-listed symbols from the NASDAQ FTP server.

    Returns:
        list: A list of all stock symbols, or an empty list if download fails.
    """
    all_symbols = set()
    urls = [
        'ftp://ftp.nasdaqtrader.com/symboldirectory/nasdaqlisted.txt',
        'ftp://ftp.nasdaqtrader.com/symboldirectory/otherlisted.txt'
    ]

    print("Downloading full list of NASDAQ symbols...")

    for url in urls:
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                # Use io.TextIOWrapper to decode the byte stream as text
                text_stream = io.TextIOWrapper(response, encoding='utf-8')
                
                # Skip the header line
                next(text_stream)

                for line in text_stream:
                    # The file is pipe-delimited. Symbol is the first column.
                    parts = line.split('|')
                    if len(parts) > 1:
                        symbol = parts[0].strip()
                        # Exclude test stocks and invalid symbols
                        if symbol and '.' not in symbol and '$' not in symbol:
                            all_symbols.add(symbol)
            
        except Exception as e:
            print(f"Warning: Could not download or process ticker list from {url}. Error: {e}")
            # Continue to the next URL if one fails
            continue

    # The last line of the file is a timestamp, remove it if it was added
    if 'File Creation Time' in all_symbols:
        all_symbols.remove('File Creation Time')

    if all_symbols:
        print(f"Successfully downloaded {len(all_symbols)} unique symbols.")
        return sorted(list(all_symbols))
    else:
        print("Warning: Failed to download any symbols. Using fallback list.")
        return []
