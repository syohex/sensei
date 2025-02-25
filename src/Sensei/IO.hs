{-# LANGUAGE RankNTypes #-}

module Sensei.IO where

import Data.Aeson (eitherDecode, encode)
import qualified Data.ByteString.Lazy as LBS
import Sensei.Client.Monad (ClientConfig, defaultConfig)
import System.Directory
import System.FilePath ((</>))

getConfigDirectory :: IO FilePath
getConfigDirectory = do
  home <- getXdgDirectory XdgConfig "sensei"
  createDirectoryIfMissing True home
  pure home

getDataDirectory :: IO FilePath
getDataDirectory = do
  home <- getXdgDirectory XdgData "sensei"
  createDirectoryIfMissing True home
  pure home

readConfig :: IO ClientConfig
readConfig = do
  dir <- getConfigDirectory
  let configFile = dir </> "client.json"
  configExists <- doesFileExist configFile
  if configExists
    then do
      bs <- LBS.readFile configFile
      case eitherDecode bs of
        Right conf -> pure conf
        Left err -> error $ "Configuration file " <> configFile <> " does not contain valid ClientConfig: " <> err
    else pure defaultConfig

writeConfig :: ClientConfig -> IO ()
writeConfig config = do
  dir <- getConfigDirectory
  let configFile = dir </> "client.json"
  LBS.writeFile configFile (encode config)
