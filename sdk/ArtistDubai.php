<?php
declare(strict_types=1);

namespace ArtistDubai\Sdk;

/**
 * ============================================================================
 * Artist Dubai - Standalone OOP Base API & Service Layer SDK
 * Version: 1.0.0
 * Architecture: Clean Object-Oriented Client & Domain Service Layer
 * Designed for: Custom external integrations (WordPress, Laravel, custom PHP)
 * ============================================================================
 */

// ============================================================================
// 1. Exceptions Hierarchy
// ============================================================================

namespace ArtistDubai\Sdk\Exceptions;

class ApiException extends \Exception {
    protected int $statusCode;
    protected mixed $responseBody;

    public function __construct(string $message = '', int $statusCode = 0, mixed $responseBody = null, ?\Throwable $previous = null) {
        $this->statusCode = $statusCode;
        $this->responseBody = $responseBody;
        parent::__construct($message, $statusCode, $previous);
    }

    public function getStatusCode(): int {
        return $this->statusCode;
    }

    public function getResponseBody(): mixed {
        return $this->responseBody;
    }
}

class AuthenticationException extends ApiException {}
class NotFoundException extends ApiException {}
class ValidationException extends ApiException {
    protected array $errors = [];

    public function __construct(string $message = '', int $statusCode = 400, mixed $responseBody = null, array $errors = [], ?\Throwable $previous = null) {
        $this->errors = $errors;
        parent::__construct($message, $statusCode, $responseBody, $previous);
    }

    public function getErrors(): array {
        return $this->errors;
    }
}
class RateLimitException extends ApiException {
    protected int $retryAfter = 60;

    public function __construct(string $message = '', int $statusCode = 429, int $retryAfter = 60, mixed $responseBody = null, ?\Throwable $previous = null) {
        $this->retryAfter = $retryAfter;
        parent::__construct($message, $statusCode, $responseBody, $previous);
    }

    public function getRetryAfter(): int {
        return $this->retryAfter;
    }
}
class ServerException extends ApiException {}
class ConnectionException extends ApiException {}


// ============================================================================
// 2. HTTP Transport & Response Objects
// ============================================================================

namespace ArtistDubai\Sdk\Http;

use ArtistDubai\Sdk\Exceptions\ApiException;
use ArtistDubai\Sdk\Exceptions\AuthenticationException;
use ArtistDubai\Sdk\Exceptions\ConnectionException;
use ArtistDubai\Sdk\Exceptions\NotFoundException;
use ArtistDubai\Sdk\Exceptions\RateLimitException;
use ArtistDubai\Sdk\Exceptions\ServerException;
use ArtistDubai\Sdk\Exceptions\ValidationException;

class ApiResponse {
    protected int $statusCode;
    protected array $headers;
    protected string $rawBody;
    protected mixed $data;
    protected string $message;
    protected bool $success;
    protected ?array $pagination;

    public function __construct(int $statusCode, array $headers, string $rawBody) {
        $this->statusCode = $statusCode;
        $this->headers = $headers;
        $this->rawBody = $rawBody;
        $this->parse();
    }

    protected function parse(): void {
        $decoded = json_decode($this->rawBody, true);
        if (is_array($decoded)) {
            $this->success = (bool)($decoded['success'] ?? ($this->statusCode >= 200 && $this->statusCode < 300));
            $this->message = (string)($decoded['message'] ?? '');
            $this->data = $decoded['data'] ?? $decoded;
            $this->pagination = isset($decoded['pagination']) && is_array($decoded['pagination']) ? $decoded['pagination'] : null;
        } else {
            $this->success = ($this->statusCode >= 200 && $this->statusCode < 300);
            $this->message = $this->success ? 'OK' : 'Unknown response';
            $this->data = $this->rawBody;
            $this->pagination = null;
        }
    }

    public function isSuccess(): bool {
        return $this->success;
    }

    public function getStatusCode(): int {
        return $this->statusCode;
    }

    public function getMessage(): string {
        return $this->message;
    }

    public function getData(): mixed {
        return $this->data;
    }

    public function getPagination(): ?array {
        return $this->pagination;
    }

    public function hasMore(): bool {
        return !empty($this->pagination['has_more']);
    }

    public function getRawBody(): string {
        return $this->rawBody;
    }

    public function getHeaders(): array {
        return $this->headers;
    }

    public function toArray(): array {
        return [
            'success' => $this->success,
            'status_code' => $this->statusCode,
            'message' => $this->message,
            'data' => $this->data,
            'pagination' => $this->pagination,
        ];
    }
}

class HttpClient {
    protected string $baseUrl;
    protected ?string $apiKey;
    protected ?string $token;
    protected int $timeout;
    protected int $connectTimeout;
    protected bool $verifySsl;
    protected array $customHeaders;
    protected bool $debug;

    public function __construct(array $config = []) {
        $this->baseUrl = rtrim((string)($config['base_url'] ?? 'https://technestpartners.com/api/api.php'), '/');
        $this->apiKey = isset($config['api_key']) ? (string)$config['api_key'] : null;
        $this->token = isset($config['token']) ? (string)$config['token'] : null;
        $this->timeout = (int)($config['timeout'] ?? 30);
        $this->connectTimeout = (int)($config['connect_timeout'] ?? 10);
        $this->verifySsl = (bool)($config['verify_ssl'] ?? true);
        $this->customHeaders = (array)($config['headers'] ?? []);
        $this->debug = (bool)($config['debug'] ?? false);
    }

    public function setBaseUrl(string $url): self {
        $this->baseUrl = rtrim($url, '/');
        return $this;
    }

    public function getBaseUrl(): string {
        return $this->baseUrl;
    }

    public function setApiKey(?string $apiKey): self {
        $this->apiKey = $apiKey;
        return $this;
    }

    public function setToken(?string $token): self {
        $this->token = $token;
        return $this;
    }

    public function getToken(): ?string {
        return $this->token;
    }

    public function addHeader(string $name, string $value): self {
        $this->customHeaders[$name] = $value;
        return $this;
    }

    public function get(string $resource, array $query = []): ApiResponse {
        return $this->request('GET', $resource, [], $query);
    }

    public function post(string $resource, array $data = [], array $query = []): ApiResponse {
        return $this->request('POST', $resource, $data, $query);
    }

    public function put(string $resource, array $data = [], array $query = []): ApiResponse {
        return $this->request('PUT', $resource, $data, $query);
    }

    public function delete(string $resource, array $data = [], array $query = []): ApiResponse {
        return $this->request('DELETE', $resource, $data, $query);
    }

    public function request(string $method, string $resource, array $data = [], array $query = []): ApiResponse {
        $url = $this->buildUrl($resource, $query);
        $headers = $this->buildHeaders();

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HEADER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, $this->timeout);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, $this->connectTimeout);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->verifySsl);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, $this->verifySsl ? 2 : 0);

        $method = strtoupper($method);
        switch ($method) {
            case 'POST':
                curl_setopt($ch, CURLOPT_POST, true);
                if (!empty($data)) {
                    $jsonPayload = json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, $jsonPayload);
                    $headers[] = 'Content-Type: application/json; charset=UTF-8';
                }
                break;
            case 'PUT':
            case 'PATCH':
            case 'DELETE':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
                if (!empty($data)) {
                    $jsonPayload = json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, $jsonPayload);
                    $headers[] = 'Content-Type: application/json; charset=UTF-8';
                }
                break;
            case 'GET':
            default:
                curl_setopt($ch, CURLOPT_HTTPGET, true);
                break;
        }

        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

        $response = curl_exec($ch);
        $curlError = curl_error($ch);
        $curlErrno = curl_errno($ch);
        $statusCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $headerSize = (int)curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        if (PHP_VERSION_ID < 80500) {
            @curl_close($ch);
        }

        if ($curlErrno !== 0) {
            throw new ConnectionException("API connection failed [{$curlErrno}]: {$curlError}", $statusCode);
        }

        $rawHeaders = substr((string)$response, 0, $headerSize);
        $rawBody = substr((string)$response, $headerSize);
        $parsedHeaders = $this->parseHeaders($rawHeaders);

        $apiResponse = new ApiResponse($statusCode, $parsedHeaders, $rawBody);

        // Error handling & exception throwing on failure status codes
        if ($statusCode >= 400) {
            $this->handleErrorResponse($apiResponse);
        }

        return $apiResponse;
    }

    public function uploadFile(string $resource, string $filePath, array $extraData = []): ApiResponse {
        if (!file_exists($filePath) || !is_readable($filePath)) {
            throw new \InvalidArgumentException("Upload file does not exist or is not readable: {$filePath}");
        }

        $url = $this->buildUrl($resource);
        $headers = $this->buildHeaders(false);

        $postFields = $extraData;
        $mime = mime_content_type($filePath) ?: 'application/octet-stream';
        $postFields['file'] = new \CURLFile($filePath, $mime, basename($filePath));

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $postFields);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HEADER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, max(60, $this->timeout * 2));
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->verifySsl);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

        $response = curl_exec($ch);
        $curlError = curl_error($ch);
        $curlErrno = curl_errno($ch);
        $statusCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $headerSize = (int)curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        if (PHP_VERSION_ID < 80500) {
            @curl_close($ch);
        }

        if ($curlErrno !== 0) {
            throw new ConnectionException("API upload connection failed [{$curlErrno}]: {$curlError}", $statusCode);
        }

        $rawHeaders = substr((string)$response, 0, $headerSize);
        $rawBody = substr((string)$response, $headerSize);
        $apiResponse = new ApiResponse($statusCode, $this->parseHeaders($rawHeaders), $rawBody);

        if ($statusCode >= 400) {
            $this->handleErrorResponse($apiResponse);
        }

        return $apiResponse;
    }

    protected function buildUrl(string $resource, array $query = []): string {
        $query['resource'] = trim($resource, '/');
        $queryString = http_build_query($query);
        $separator = strpos($this->baseUrl, '?') !== false ? '&' : '?';
        return $this->baseUrl . $separator . $queryString;
    }

    protected function buildHeaders(bool $includeJson = true): array {
        $headers = [];
        if ($includeJson) {
            $headers[] = 'Accept: application/json';
        }

        if (!empty($this->token)) {
            $headers[] = "Authorization: Bearer {$this->token}";
        } elseif (!empty($this->apiKey)) {
            $headers[] = "X-Api-Key: {$this->apiKey}";
            $headers[] = "Authorization: Bearer {$this->apiKey}";
        }

        foreach ($this->customHeaders as $name => $val) {
            $headers[] = "{$name}: {$val}";
        }

        return $headers;
    }

    protected function parseHeaders(string $raw): array {
        $headers = [];
        $lines = explode("\r\n", $raw);
        foreach ($lines as $line) {
            if (strpos($line, ':') !== false) {
                [$key, $val] = explode(':', $line, 2);
                $headers[trim($key)] = trim($val);
            }
        }
        return $headers;
    }

    protected function handleErrorResponse(ApiResponse $response): void {
        $code = $response->getStatusCode();
        $msg = $response->getMessage() ?: "API Error ({$code})";
        $body = $response->getData();

        switch ($code) {
            case 401:
            case 403:
                throw new AuthenticationException($msg, $code, $body);
            case 404:
                throw new NotFoundException($msg, $code, $body);
            case 400:
            case 422:
                $errors = is_array($body) && isset($body['errors']) && is_array($body['errors']) ? $body['errors'] : [];
                throw new ValidationException($msg, $code, $body, $errors);
            case 429:
                $retry = (int)($response->getHeaders()['Retry-After'] ?? 60);
                throw new RateLimitException($msg, $code, $retry, $body);
            default:
                if ($code >= 500) {
                    throw new ServerException($msg, $code, $body);
                }
                throw new ApiException($msg, $code, $body);
        }
    }
}


// ============================================================================
// 3. Domain Services (Base & Feature Modules)
// ============================================================================

namespace ArtistDubai\Sdk\Services;

use ArtistDubai\Sdk\Http\ApiResponse;
use ArtistDubai\Sdk\Http\HttpClient;

abstract class BaseService {
    protected HttpClient $client;
    protected string $resource;

    public function __construct(HttpClient $client) {
        $this->client = $client;
    }

    public function getResource(): string {
        return $this->resource;
    }

    protected function unwrap(ApiResponse $res): mixed {
        return $res->getData();
    }
}

class ArtistService extends BaseService {
    protected string $resource = 'artists';

    public function all(array $filters = []): array {
        $res = $this->client->get($this->resource, $filters);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }

    public function find(int $id): ?array {
        $res = $this->client->get($this->resource, ['id' => $id]);
        $data = $this->unwrap($res);
        if (is_array($data)) {
            return isset($data[0]) && is_array($data[0]) ? $data[0] : $data;
        }
        return null;
    }

    public function create(array $data): array {
        $res = $this->client->post($this->resource, $data);
        return (array)$this->unwrap($res);
    }

    public function update(int $id, array $data): bool {
        $data['id'] = $id;
        $res = $this->client->post($this->resource, $data, ['action' => 'update']);
        return $res->isSuccess();
    }

    public function delete(int $id): bool {
        $res = $this->client->post($this->resource, ['id' => $id], ['action' => 'delete']);
        return $res->isSuccess();
    }

    public function like(int $id): bool {
        $res = $this->client->post($this->resource, ['id' => $id], ['action' => 'like']);
        return $res->isSuccess();
    }

    public function artworks(int $artistId): array {
        $res = $this->client->get('artworks', ['artist_id' => $artistId]);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }
}

class GalleryService extends BaseService {
    protected string $resource = 'galleries';

    public function all(array $filters = []): array {
        $res = $this->client->get($this->resource, $filters);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }

    public function find(int $id): ?array {
        $res = $this->client->get($this->resource, ['id' => $id]);
        $data = $this->unwrap($res);
        if (is_array($data)) {
            return isset($data[0]) && is_array($data[0]) ? $data[0] : $data;
        }
        return null;
    }

    public function create(array $data): array {
        $res = $this->client->post($this->resource, $data);
        return (array)$this->unwrap($res);
    }

    public function update(int $id, array $data): bool {
        $data['id'] = $id;
        $res = $this->client->post($this->resource, $data, ['action' => 'update']);
        return $res->isSuccess();
    }

    public function delete(int $id): bool {
        $res = $this->client->post($this->resource, ['id' => $id], ['action' => 'delete']);
        return $res->isSuccess();
    }
}

class EventService extends BaseService {
    protected string $resource = 'events';

    public function all(array $filters = []): array {
        $res = $this->client->get($this->resource, $filters);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }

    public function find(int $id): ?array {
        $res = $this->client->get($this->resource, ['id' => $id]);
        $data = $this->unwrap($res);
        if (is_array($data)) {
            return isset($data[0]) && is_array($data[0]) ? $data[0] : $data;
        }
        return null;
    }

    public function create(array $data): array {
        $res = $this->client->post($this->resource, $data);
        return (array)$this->unwrap($res);
    }

    public function update(int $id, array $data): bool {
        $data['id'] = $id;
        $res = $this->client->post($this->resource, $data, ['action' => 'update']);
        return $res->isSuccess();
    }

    public function delete(int $id): bool {
        $res = $this->client->post($this->resource, ['id' => $id], ['action' => 'delete']);
        return $res->isSuccess();
    }

    public function galleries(int $eventId): array {
        $res = $this->client->get('galleries', ['event_id' => $eventId]);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }
}

class ArtworkService extends BaseService {
    protected string $resource = 'artworks';

    public function all(array $filters = []): array {
        $res = $this->client->get($this->resource, $filters);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }

    public function find(int $id): ?array {
        $res = $this->client->get($this->resource, ['id' => $id]);
        $data = $this->unwrap($res);
        if (is_array($data)) {
            return isset($data[0]) && is_array($data[0]) ? $data[0] : $data;
        }
        return null;
    }

    public function create(array $data): array {
        $res = $this->client->post($this->resource, $data);
        return (array)$this->unwrap($res);
    }

    public function update(int $id, array $data): bool {
        $data['id'] = $id;
        $res = $this->client->post($this->resource, $data, ['action' => 'update']);
        return $res->isSuccess();
    }

    public function delete(int $id): bool {
        $res = $this->client->post($this->resource, ['id' => $id], ['action' => 'delete']);
        return $res->isSuccess();
    }

    public function like(int $id): bool {
        $res = $this->client->post($this->resource, ['id' => $id], ['action' => 'like']);
        return $res->isSuccess();
    }
}

class BookingService extends BaseService {
    protected string $resource = 'bookings';

    public function all(array $filters = []): array {
        $res = $this->client->get($this->resource, $filters);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }

    public function create(array $data): array {
        $res = $this->client->post($this->resource, $data);
        return (array)$this->unwrap($res);
    }

    public function updateStatus(int $id, string $status): bool {
        $res = $this->client->post($this->resource, ['id' => $id, 'status' => $status], ['action' => 'update']);
        return $res->isSuccess();
    }
}

class AuthService extends BaseService {
    protected string $resource = 'login';

    public function login(string $email, string $password): array {
        $res = $this->client->post($this->resource, [
            'email' => $email,
            'password' => $password,
        ]);
        $data = (array)$this->unwrap($res);
        if (!empty($data['token'])) {
            $this->client->setToken((string)$data['token']);
        }
        return $data;
    }

    public function register(array $userData): array {
        $res = $this->client->post($this->resource, $userData, ['action' => 'register']);
        $data = (array)$this->unwrap($res);
        if (!empty($data['token'])) {
            $this->client->setToken((string)$data['token']);
        }
        return $data;
    }

    public function profile(): ?array {
        $res = $this->client->get($this->resource, ['action' => 'profile']);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : null;
    }

    public function changePassword(string $oldPassword, string $newPassword): bool {
        $res = $this->client->post($this->resource, [
            'old_password' => $oldPassword,
            'new_password' => $newPassword,
        ], ['action' => 'change_password']);
        return $res->isSuccess();
    }
}

class CategoryService extends BaseService {
    protected string $resource = 'categories';

    public function all(string $type = 'all'): array {
        $res = $this->client->get($this->resource, ['type' => $type]);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }

    public function experienceLevels(): array {
        $res = $this->client->get('experience_levels');
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }

    public function locations(): array {
        $res = $this->client->get('locations');
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }
}

class NotificationService extends BaseService {
    protected string $resource = 'notifications';

    public function forUser(string $email): array {
        $res = $this->client->get($this->resource, ['email' => $email]);
        $data = $this->unwrap($res);
        return is_array($data) ? $data : [];
    }

    public function markAsRead(int $id): bool {
        $res = $this->client->post($this->resource, ['id' => $id], ['action' => 'read']);
        return $res->isSuccess();
    }

    public function send(array $data): bool {
        $res = $this->client->post($this->resource, $data);
        return $res->isSuccess();
    }
}

class UploadService extends BaseService {
    protected string $resource = 'upload';

    public function uploadFile(string $filePath): string {
        $res = $this->client->uploadFile($this->resource, $filePath);
        $data = $this->unwrap($res);
        if (is_array($data) && !empty($data['url'])) {
            return (string)$data['url'];
        }
        if (is_string($data) && !empty($data)) {
            return $data;
        }
        return '';
    }

    public function uploadBase64(string $base64, string $ext = 'jpg'): string {
        $res = $this->client->post($this->resource, [
            'base64' => $base64,
            'ext' => $ext,
        ]);
        $data = $this->unwrap($res);
        if (is_array($data) && !empty($data['url'])) {
            return (string)$data['url'];
        }
        return '';
    }
}

class AiChatService extends BaseService {
    protected string $resource = 'ai_chat';

    public function chat(string $message, string $sessionId = '', array $history = []): array {
        $res = $this->client->post($this->resource, [
            'message' => $message,
            'session_id' => $sessionId,
            'history' => $history,
        ]);
        return (array)$this->unwrap($res);
    }
}


// ============================================================================
// 4. Main Client Facade
// ============================================================================

namespace ArtistDubai\Sdk;

use ArtistDubai\Sdk\Http\ApiResponse;
use ArtistDubai\Sdk\Http\HttpClient;
use ArtistDubai\Sdk\Services\AiChatService;
use ArtistDubai\Sdk\Services\ArtistService;
use ArtistDubai\Sdk\Services\ArtworkService;
use ArtistDubai\Sdk\Services\AuthService;
use ArtistDubai\Sdk\Services\BookingService;
use ArtistDubai\Sdk\Services\CategoryService;
use ArtistDubai\Sdk\Services\EventService;
use ArtistDubai\Sdk\Services\GalleryService;
use ArtistDubai\Sdk\Services\NotificationService;
use ArtistDubai\Sdk\Services\UploadService;

/**
 * ArtistDubai - Unified OOP Client Facade
 *
 * Usage:
 *   $client = new \ArtistDubai\Sdk\ArtistDubai([
 *       'base_url' => 'https://technestpartners.com/api/api.php',
 *       'api_key' => 'YOUR_API_KEY',
 *   ]);
 *
 *   $galleries = $client->galleries->all(['limit' => 5]);
 *   $artists   = $client->artists->all();
 */
class ArtistDubai {
    protected HttpClient $http;

    public ArtistService $artists;
    public GalleryService $galleries;
    public EventService $events;
    public ArtworkService $artworks;
    public BookingService $bookings;
    public AuthService $auth;
    public CategoryService $categories;
    public NotificationService $notifications;
    public UploadService $uploads;
    public AiChatService $aiChat;

    public function __construct(array $config = []) {
        $this->http = new HttpClient($config);
        $this->initServices();
    }

    protected function initServices(): void {
        $this->artists = new ArtistService($this->http);
        $this->galleries = new GalleryService($this->http);
        $this->events = new EventService($this->http);
        $this->artworks = new ArtworkService($this->http);
        $this->bookings = new BookingService($this->http);
        $this->auth = new AuthService($this->http);
        $this->categories = new CategoryService($this->http);
        $this->notifications = new NotificationService($this->http);
        $this->uploads = new UploadService($this->http);
        $this->aiChat = new AiChatService($this->http);
    }

    public function getHttpClient(): HttpClient {
        return $this->http;
    }

    public function setBaseUrl(string $url): self {
        $this->http->setBaseUrl($url);
        return $this;
    }

    public function setApiKey(?string $apiKey): self {
        $this->http->setApiKey($apiKey);
        return $this;
    }

    public function setToken(?string $token): self {
        $this->http->setToken($token);
        return $this;
    }

    // Direct HTTP request proxies
    public function get(string $resource, array $query = []): ApiResponse {
        return $this->http->get($resource, $query);
    }

    public function post(string $resource, array $data = [], array $query = []): ApiResponse {
        return $this->http->post($resource, $data, $query);
    }

    public function put(string $resource, array $data = [], array $query = []): ApiResponse {
        return $this->http->put($resource, $data, $query);
    }

    public function delete(string $resource, array $data = [], array $query = []): ApiResponse {
        return $this->http->delete($resource, $data, $query);
    }
}
