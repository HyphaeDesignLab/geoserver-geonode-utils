<?php
/**
 * Created by PhpStorm.
 * User: ivanvelev
 * Date: 5/22/20
 * Time: 12:59 PM
 */


/**
 * Class MapboxApi
 *
 */

function debugLog($something, $skipErrorLog=False) {
    $text = '';
    if ( $something instanceof Exception ) {
        $text = $something->getMessage();
    } else if ( is_string($something)) {
        $text = $something;
    } else {
        $text = json_encode( $something, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT );
    }
    if (!$skipErrorLog) {
        error_log($text);
    }
    if (ini_get('display_errors')) {
        if (strpos($text, '/') === 0) {
            echo "file:///";
        }
        echo $text;
        echo "\n";
    }
}
class MapboxApi {
    protected static function backupFile($filePath) {
        if (file_exists($filePath)) {
            // if not ABS path, add current dir to it
            if (strpos($filePath, '/') !== 0) {
                $filePath = dirname(__FILE__) . '/' . $filePath;
            }

            $now = new DateTime();

            $fileDir = dirname($filePath);
            $fileDirBackup = $fileDir . '/backup';

            $fileName = str_replace($fileDir, '', $filePath);
            $fileNameBackup = str_replace('.json', '.'.$now->format('Y_m_d_H_i_s').'.json', $fileName);

            if (!file_exists($fileDirBackup)) {
                mkdir($fileDirBackup, 0774, true);
            }
            shell_exec(sprintf('mv "%s" "%s/%s"', $filePath, $fileDirBackup, $fileNameBackup));
        }
    }

    /**
     * @param $path
     * @param bool $outputFile
     *
     * @return array
     * @throws Exception
     */
    protected static function exec($path, $outputFile=false, $options=array()) {
        $cmdArray = ['curl'];
        if (!isset($options['method'])) {
            $options['method'] = 'GET';
        }
        $cmdArray[] = '-X '.$options['method'];
        if (isset($options['header'])) {
            $cmdArray[] = sprintf("--header '%s'", $options['header']);
        }
        if (isset($options['data'])) {
            $cmdArray[] = sprintf("--data '%s'", $options['data']);
        }
        if (isset($options['form'])) {
            $cmdArray[] = sprintf("--form '%s'", $options['form']);
        }

        $url = MAPBOX_API_URL . '/' . trim($path, '/');
        $cmdArray[] = $url;
        // $cmdArray[] = '2>/dev/null';
        $cmd = sprintf(implode(' ', $cmdArray));
        $cmd = str_replace( "\n", ' ', $cmd );
        debugLog($cmd);
        debugLog($outputFile);
        $out = shell_exec( $cmd );

        if (empty($out) || $out === 'null') {
            throw new Exception('Mapbox api failed');
        }

        $json = json_decode($out, true);
        if ($outputFile) {
            self::backupFile($outputFile);
            if (!file_exists(dirname($outputFile))) {
                mkdir(dirname($outputFile), 0774, true);
            }
            $jsonString = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

            // For STYLE:LAYOUT
            // Make sure to fix empty assoc array conversion to [] (must be {})
            $jsonString = str_replace('"layout": []', '"layout": {}', $jsonString);

            file_put_contents($outputFile, $jsonString);

            // CHECK FOR OTHER POTENTIAL empty array issues
            if (strpos($jsonString, '[]')) {
                debugLog('WARNING!!! Potential empty JSON array php-to-string issue:' .$jsonString);
            }
        }
        return $json;
    }

    /**
     * @param $apiPath
     * @param $outputDir
     * @param bool $fromCache
     *
     * @return array|bool|\Exception
     */
    protected static function getList($apiPath, $outputDir, $fromCache=false) {
        $url = sprintf('/%s/%s?access_token=%s', $apiPath, MAPBOX_USER, MAPBOX_TOKEN);
        $outFile = sprintf('%s/%s/_list.json', dirname(__FILE__), $outputDir);

        try {
            $json = self::exec($url, $outFile);
        } catch (Exception $e) {
            return $e;
        }

        return $json;
    }

    /**
     * @return array|bool
     */
    protected static function getTilesetList() {
        return self::getList('tilesets/v1', 'tilesets');
    }

    /**
     *
     */
    protected static function getTilesetsMeta() {
        $tilesets = self::getTilesetList();
        $i=0;
        foreach($tilesets as $tileset) {
            self::getTilesetMeta($tileset['id']);
            if (++$i % 10 === 0) {
                sleep(1);
            }
        }
        return count($tilesets) . ' tilesets';
    }
    protected static function getTilesetMeta($id, $fromCache=false) {
        $id = str_replace(MAPBOX_USER.'.', '', $id); // just in case, strip username prefix
        $apiPath = 'v4';
        $outputDir = 'tilesets/';
        $url = sprintf('/%s/%s.%s.json?access_token=%s', $apiPath, MAPBOX_USER, $id, MAPBOX_TOKEN);
        $outFile = sprintf('%s/%s/%s.json', dirname(__FILE__), $outputDir, $id);

        try {
            if ($fromCache && file_exists($outFile)) {
                return json_decode(file_get_contents($outFile), true);
            }
            return self::exec($url, $outFile);
        } catch (Exception $e) {
            return $e;
        }
    }

    protected static function updateTileset($id, $data) {
        $apiPath = "tilesets/v1";
        $url = sprintf('/%s/%s.%s/?access_token=%s', $apiPath, MAPBOX_USER, $id, MAPBOX_TOKEN_UPLOADS);
        $outFile = sprintf('%s/_tilesets/update/%s.json', dirname(__FILE__), $id);

        try {
            $json = self::exec($url, $outFile, ['data'=>$data, 'method' => 'PATCH']);
        } catch (Exception $e) {
            return $e;
        }

        return $json;

    }

    // https://docs.mapbox.com/api/maps/mapbox-tiling-service/#create-a-tileset
    protected static function createTileset($id, $sources) {
        $url = sprintf('/tilesets/v1/%s.%s?access_token=%s', MAPBOX_USER, substr($id, 0, 32), MAPBOX_TOKEN_UPLOADS);
        $outFile = sprintf('%s/_tilesets/create/%s.json', dirname(__FILE__), $id);

        if (empty($sources)) {
            return 'sources cannot be empty';
        }
        try {
            $layers = [];
            foreach($sources as $sourceId) {
                $layers[$sourceId] = [
                      'source'=> sprintf('mapbox://_tilesets/source/%s/%s', MAPBOX_USER, $sourceId),
                      'minzoom'=> 3,
                      'maxzoom' => 12
                ];
            }
            $json = self::exec($url, $outFile, ['data'=>json_encode([
                  'name' => str_replace(['-', '_'], ' ', $id),
                  'recipe'=> [
                        'version'=> 1,
                        'layers'=>$layers
                  ]
            ], JSON_UNESCAPED_SLASHES), 'method' => 'POST', 'header' => 'Content-Type:application/json']);
        } catch (Exception $e) {
            return $e;
        }

        return $json;

    }
    // https://docs.mapbox.com/api/maps/mapbox-tiling-service/#publish-a-tileset
    protected static function publishTileset($id) {
        $url = sprintf('/tilesets/v1/%s.%s/publish?access_token=%s', MAPBOX_USER, substr($id, 0, 32), MAPBOX_TOKEN_UPLOADS);
        $outFile = sprintf('%s/_tilesets/publish/%s.json', dirname(__FILE__), $id);

        try {
            $json = self::exec($url, $outFile, ['method' => 'POST']);
        } catch (Exception $e) {
            return $e;
        }

        return $json;

    }

    // https://docs.mapbox.com/api/maps/mapbox-tiling-service/#list-information-about-all-jobs-for-a-tileset
    protected static function getTilesetJobs($id) {
        $url = sprintf('/tilesets/v1/%s.%s/jobs?access_token=%s', MAPBOX_USER, substr($id, 0, 32), MAPBOX_TOKEN_UPLOADS);
        $outFile = sprintf('%s/_tilesets/jobs/%s.json', dirname(__FILE__), $id);

        try {
            $json = self::exec($url, $outFile);
        } catch (Exception $e) {
            return $e;
        }

        return $json;
    }
    protected static function getTilesetJob($id, $jobId) {
        $url = sprintf('/tilesets/v1/%s.%s/jobs/%s?access_token=%s', MAPBOX_USER, $id, $jobId, MAPBOX_TOKEN_UPLOADS);
        $outFile = sprintf('%s/_tilesets/jobs/%s.json', dirname(__FILE__), $id.'_'.$jobId);

        try {
            $json = self::exec($url, $outFile);
        } catch (Exception $e) {
            return $e;
        }

        return $json;
    }
    protected static function getTilesetRecipe($id) {
        $apiPath = 'tilesets/v1';
        $outputDir = 'tilesets/';
        $url = sprintf('/%s/%s.%s/recipe?access_token=%s', $apiPath, MAPBOX_USER, $id, MAPBOX_TOKEN);
        $outFile = sprintf('%s/%s/%s-recipe.json', dirname(__FILE__), $outputDir, $id);

        try {
            $json = self::exec($url, $outFile);
        } catch (Exception $e) {
            return $e;
        }

        return $json;
    }
    // https://docs.mapbox.com/api/maps/mapbox-tiling-service/#create-a-tileset-source
    protected static function createTilesetSource($id, $filePath) {
        $url = sprintf('/tilesets/v1/sources/%s/%s?access_token=%s', MAPBOX_USER, $id, MAPBOX_TOKEN_UPLOADS);
        $outFile = sprintf('%s/_tilesets/source-create/%s.json', dirname(__FILE__), $id);

        try {
            $json = self::exec($url, $outFile, ['form'=>'file=@'.$filePath, 'method' => 'POST']);
        } catch (Exception $e) {
            return $e;
        }

        return $json;

    }
    protected static function getTilesetSourceList() {
        return self::getList('tilesets/v1/sources', 'tilesets/sources');
    }
    protected static function getTilesetSource($id, $isDraft=false) {
        $apiPath = 'tilesets/v1/sources';
        $outputDir = 'tilesets/';
        $url = sprintf('/%s/%s/%s?access_token=%s', $apiPath, MAPBOX_USER, $id, MAPBOX_TOKEN);
        $outFile = sprintf('%s/%s/%s.json', dirname(__FILE__), $outputDir, $id);

        try {
            $json = self::exec($url, $outFile);
        } catch (Exception $e) {
            return $e;
        }

        return $json;
    }

    protected static function getStylesList() {
        return self::getList('styles/v1', 'styles/raw');
    }

    protected static function getStyle($id, $isDraft=false, $options=[]) {
        $apiPath = 'styles/v1';
        $outputDir = 'styles/raw';
        $url = sprintf('/%s/%s/%s%s?access_token=%s', $apiPath, MAPBOX_USER, $id, $isDraft ? '/draft':'', MAPBOX_TOKEN);
        $outFile = sprintf('%s/%s/%s.json', dirname(__FILE__), $options['outputDir'] ?? $outputDir, $options['outputName'] ?? $id);

        try {
            $json = self::exec($url, $outFile);
        } catch (Exception $e) {
            return $e;
        }

        return $json;
    }

    protected static function createStyle($styleJsonFile, $filePath) {
        $apiPath = 'styles/v1';
        $url = sprintf('/%s/%s?access_token=%s', $apiPath, MAPBOX_USER, MAPBOX_TOKEN_UPLOADS);
        if (!file_exists($styleJsonFile)) {
            return "Style JSON file does not exist $styleJsonFile \n";
        }
        try {
            $json = json_decode(file_get_contents($styleJsonFile));
        } catch(Exception $e) {
            $error = $e->getMessage();
            return "Style JSON is not formatted properly $styleJsonFile: $error \n";
        }

        $outFile = sprintf('%s/%s.json', $filePath, 'create');

        try {
            $response = self::exec($url, $outFile, array('data' => '@'.$styleJsonFile, 'method'=>'POST'));
        } catch (Exception $e) {
            return $e;
        }

        return $response;
    }

    // https://docs.mapbox.com/api/maps/mapbox-tiling-service/#publish-a-tileset
    protected static function viewJobQueue() {
        $url = sprintf('/tilesets/v1/queue?access_token=%s', MAPBOX_TOKEN_UPLOADS);
        $outFile = sprintf('%s/_tilesets/jobs/queue.json', dirname(__FILE__));

        try {
            $json = self::exec($url, $outFile, ['method' => 'PUT']);
        } catch (Exception $e) {
            return $e;
        }

        return $json;

    }

    private static function ParseConfig() {
        $config = parse_ini_file('config.ini');
        foreach($config as $k=>$v) {
            define($k, $v);
        }
    }
    private static $originalWorkingDir = '';
    public static function Main($args) {
        self::$originalWorkingDir = getcwd();
        chdir(dirname(__FILE__));
        self::ParseConfig();
        $usageText = <<<USAGE

Usage of script:
    tilesets
    tilesets_all_meta
    tileset_meta id=ID
    styles
    style id=ID  title="SOME TITLE"
    create_style config=file/path/to/config.json


USAGE;
        $action = $args[1];
        if (empty($action)) {
            echo $usageText;
            exit();
        }

        $params = [];
        foreach($args as $arg) {
            if (strpos($arg, '=')===false) {
                continue;
            }
            list($name, $value) = explode('=', $arg);
            $params[$name] = $value;
        }
        switch($action) {
            case 'tilesets':
                return self::getTilesetList();
            case 'tileset_update':
                return self::updateTileset($params['id'], $params['data']);
            case 'tileset_sources_list':
                return self::getTilesetSourceList();
            case 'tileset_source_create':
                return self::createTilesetSource($params['id'], self::$originalWorkingDir.'/'.$params['file']);
            case 'tileset_create':
                return self::createTileset($params['id'], explode(',', $params['sources'] ?? ''));
            case 'tileset_publish':
                return self::publishTileset($params['id']);
            case 'tileset_jobs':
                return self::getTilesetJobs($params['id']);
            case 'tileset_job':
                return self::getTilesetJob($params['id'], $params['job_id']);
            case 'tileset_create_and_publish':
                 self::createTilesetSource($params['id'], self::$originalWorkingDir.'/'.$params['file']);
                self::createTileset($params['id'], [$params['id']]);
                self::publishTileset($params['id']);
                return self::getTilesetJobs($params['id']);
            case 'tilesets_all_meta':
                return self::getTilesetsMeta();
            case 'tileset_meta':
                if (empty($params['id'])) {
                    echo "\n\nPlease provide all parameters: \n $action id=ID \n\n";
                    exit();
                }
                return self::getTilesetMeta($params['id']);
            case 'styles':
                return self::getStylesList();
            case 'style':
                if (empty($params['id']) || empty($params['title'])) {
                    echo "\n\n Please provide all parameters: \n $action id=ID  title=\"SOME TITLE\" \n\n";
                    exit();
                }
                return self::getStyle($params['id'], false, ['outputName'=>$params['title']]);
            case 'create_style':
                return self::createStyle($params['config'], './api-responses/');
            case 'job_queue':
                return self::viewJobQueue();
            default:
                return $usageText;
        }
    }
}

$out = MapboxApi::Main($argv);
debugLog($out, true);