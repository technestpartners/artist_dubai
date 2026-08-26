<?php
// Fallback redirect for Laragon if Apache mod_rewrite is disabled
header("Location: ./build/web/");
exit;
