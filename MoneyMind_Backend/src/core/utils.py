import datetime
import logging

logger = logging.getLogger(__name__)

def get_current_timestamp_iso() -> str:
    """Returns the current timestamp in ISO format."""
    return datetime.datetime.now().isoformat()

def sanitize_filename(filename: str) -> str:
    """Removes potentially problematic characters from filenames."""
    return "".join(c for c in filename if c.isalnum() or c in ('_', '-')).rstrip()