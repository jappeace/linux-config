# shared services between machines

{
  services = {
    syncthing = {
      overrideDevices = true;
      overrideFolders = true;
      settings.folders = {
        "/home/jappie/phone" = {
          id = "Phone";
        };
        "/home/jappie/docs" = {
          id = "docs";
        };
        "/home/jappie/pixel_8_fmnx-photos" = {
          id = "pixel_8_fmnx-photos";
        };
        "/home/jappie/sm-a515f_nca9-foto's" = {
          id = "sm-a515f_nca9-foto's";
        };
        "/home/jappie/yt-trash" = {
          id = "uiyvz-makk2";
        };
      };
      # self TRFG2TO-MFLXN2M-U56IH3L-WUOZSC5-7TOG5JF-RU7BUCK-XJ6TBEL-TYVITAF
      settings.devices = {
        lenovo-tablet = {
          id = "ZMD43PD-V6PG3JK-SEXC6JH-36REYED-4JXHIAB-CD6EZ7K-GNX4FYT-QPGBUAB";
          introducer = true;
        };
        macbook-2024 = {
          id = "KCR5UCR-ZEE72VV-5QMRKZ7-MAE3ZAJ-V2LLVFT-XKQHMDH-MQ5K5OO-DGMLRAJ";
          introducer = true;
        };
        work-machine = {
          id = "TRFG2TO-MFLXN2M-U56IH3L-WUOZSC5-7TOG5JF-RU7BUCK-XJ6TBEL-TYVITAF";
          introducer = true;
        };
        phone = {
          id = "LXR3SCJ-3VNYE63-C5SPZUW-E3D4QRE-2X7UGLM-LFDM5XI-CH7CBFT-2RS3BAH";
          introducer = true;
        };
        lenovo-amd-2022 = {
          id = "4CEXJ25-KLOIS5N-7CBFEIU-D2JZ72G-GBYGUZS-W3JA7OU-YV4CCFT-CIBVCAX";
          introducer = true;
        };
        pixel = {
          id = "3NP65RT-WV2VIQA-SZKIZQN-LOOJ542-PQ6WSIV-YHGJVPH-HMBOUGL-WTYTDAP";
          introducer = true;
        };
      };
      enable = true;
      user = "jappie";
      group = "users";
      dataDir = "/home/jappie/.config/syncthing-private";
    };
  };
}
