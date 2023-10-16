import functools
import inspect

import pytest

from pragy_dl.networking import RequestHandler
from pragy_dl.networking.common import _REQUEST_HANDLERS
from pragy_dl.utils._utils import _YDLLogger as FakeLogger


@pytest.fixture
def handler(request):
    RH_KEY = request.param
    if inspect.isclass(RH_KEY) and issubclass(RH_KEY, RequestHandler):
        handler = RH_KEY
    elif RH_KEY in _REQUEST_HANDLERS:
        handler = _REQUEST_HANDLERS[RH_KEY]
    else:
        pytest.skip(f'{RH_KEY} request handler is not available')

    return functools.partial(handler, logger=FakeLogger)
