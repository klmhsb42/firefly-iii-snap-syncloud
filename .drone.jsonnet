local name = "firefly-iii";
local browser = "firefox";
local firefly_version = "latest"; // You can specify the version here if needed
local redis_version = "7.0.15";
local mariadb_version = "lts";
local nginx_version = "1.24.0";
local deployer = "https://github.com/syncloud/store/releases/download/4/syncloud-release";

local build(arch, test_ui, dind) = [{
    kind: "pipeline",
    type: "docker",
    name: arch,
    platform: {
        os: "linux",
        arch: arch
    },
    steps: [
        {
            name: "version",
            image: "debian:buster-slim",
            commands: [
                "echo $DRONE_BUILD_NUMBER > version"
            ]
        },
        {
            name: "download",
            image: "debian:buster-slim",
            commands: [
                "./download.sh " + firefly_version
            ]
        },
        {
            name: "nginx",
            image: "docker:" + dind,
            commands: [
                "./nginx/build.sh " + nginx_version
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "redis",
            image: "redis:" + redis_version,
            commands: [
                "./redis/build.sh"
            ]
        },
        {
            name: "postgresql",
            image: "docker:" + dind,
            commands: [
                "./postgresql/build.sh"
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "mariadb",
            image: "mariadb:" + mariadb_version,
            commands: [
                "./mariadb/build.sh"
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "build",
            image: "debian:buster-slim",
            commands: [
                "./build.sh"
            ]
        },
        {
            name: "package",
            image: "debian:buster-slim",
            commands: [
                "VERSION=$(cat version)",
                "./package.sh " + name + " $VERSION "
            ]
        },
        {
            name: "test",
            image: "python:3.8-slim-buster",
            commands: [
              "APP_ARCHIVE_PATH=$(realpath $(cat package.name))",
              "cd integration",
              "./deps.sh",
              "py.test -x -s verify.py --distro=buster --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=" + name + ".buster.com --app=" + name + " --arch=" + arch
            ]
        }
    ] + ( if test_ui then [
        {
            name: "test-ui",
            image: "python:3.8-slim-buster",
            commands: [
              "cd integration",
              "./deps.sh",
              "py.test -x -s test-ui.py --distro=buster --ui-mode=desktop --domain=buster.com --device-host=" + name + ".buster.com --app=" + name + " --browser=" + browser,
            ]
        }
    ] else [] ) + [
        {
            name: "upload",
            image: "debian:buster-slim",
            environment: {
                AWS_ACCESS_KEY_ID: {
                    from_secret: "AWS_ACCESS_KEY_ID"
                },
                AWS_SECRET_ACCESS_KEY: {
                    from_secret: "AWS_SECRET_ACCESS_KEY"
                },
                SYNCLOUD_TOKEN: {
                    from_secret: "SYNCLOUD_TOKEN"
                }
            },
            commands: [
                "PACKAGE=$(cat package.name)",
                "apt update && apt install -y wget",
                "wget " + deployer + "-" + arch + " -O release --progress=dot:giga",
                "chmod +x release",
                "./release publish -f $PACKAGE -b $DRONE_BRANCH"
            ],
            when: {
                branch: ["stable", "master"],
                event: [ "push" ]
            }
        },
        {
            name: "promote",
            image: "debian:buster-slim",
            environment: {
                AWS_ACCESS_KEY_ID: {
                    from_secret: "AWS_ACCESS_KEY_ID"
                },
                AWS_SECRET_ACCESS_KEY: {
                    from_secret: "AWS_SECRET_ACCESS_KEY"
                },
                SYNCLOUD_TOKEN: {
                    from_secret: "SYNCLOUD_TOKEN"
                }
            },
            commands: [
                "apt update && apt install -y wget",
                "wget " + deployer + "-" + arch + " -O release --progress=dot:giga",
                "chmod +x release",
                "./release promote -n " + name + " -a $(dpkg --print-architecture)"
            ],
            when: {
                branch: ["stable"],
                event: ["push"]
            }
        }
    ],
    trigger: {
        event: [
            "push",
            "pull_request"
        ]
    },
    services: [
        {
            name: "docker",
            image: "docker:" + dind,
            privileged: true,
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: name + ".buster.com",
            image: "syncloud/platform-buster-" + arch + ":22.02",
            privileged: true,
            volumes: [
                {
                    name: "dbus",
                    path: "/var/run/dbus"
                },
                {
                    name: "dev",
                    path: "/dev"
                }
            ]
        }
    ],
    volumes: [
        {
            name: "dbus",
            host: {
                path: "/var/run/dbus"
            }
        },
        {
            name: "dev",
            host: {
                path: "/dev"
            }
        },
        {
            name: "dockersock",
            temp: {}
        }
    ]
}];

build("amd64", true, "20.10.21-dind") +
build("arm64", false, "19.03.8-dind")
