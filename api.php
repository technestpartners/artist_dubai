<?php
/**
 * Artist Dubai - Root API Bootstrap Forwarder
 *
 * Forwards requests on local web servers (Laragon / Apache virtual hosts)
 * to the centralized backend implementation in `api/api.php`.
 * Eliminates duplicate maintenance of the 11,500+ line API controller.
 */

declare(strict_types=1);

require_once __DIR__ . '/api/api.php';
