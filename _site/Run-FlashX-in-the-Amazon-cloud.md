# Run FlashX in the Amazon cloud

## Launch an instance with an FlashX AMI
The FlashX AMI is in US West (Oregon). Before launching an Amazon instance, users need to choose the right region.

When launching an Amazon instance, the first step is to choose an Amazon Machine Image (AMI). Instead of choosing an AMI in "Quick Start" tab, users can choose one from "Community AMIs". Users can search for "FlashX". Currently, there is an AMI named "FlashX-v" with different version numbers in the search result. After choosing the wanted AMI, users can launch an Amazon instance. Users can select an instance type based on their needs. To run FlashX on SSDs, users can choose `i2` instances. The largest `i2` instance is `i2.8xlarge`, which has 8 SSDs.

For users who aren't familiar with the Amazon cloud, please refer to [Get Started](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html) for details.

## Configure FlashX in an Amazon instance
The FlashX AMI has preinstalled all of the FlashX components in `/home/ubuntu/FlashX`. FlashX is compiled in `/home/ubuntu/FlashX/build` and FlashR has been preinstalled.

If users want to use FlashX with SSDs, users need to configure SSDs for FlashX. To simplify the configuration, we provide a perl script `conf/set_amazon_ssds.pl`. **NOTE: the script is specifically written for FlashX in an Amazon instance.** It takes a device file, where each line is an SSD device. An example of the device file is shown in `conf/ssds.txt`. Users only need to provide device names such as `xvd?`. When users run `perl conf/set_amazon_ssds.pl conf/ssds.txt` in the top directory of FlashX, it configures the system parameters and outputs a file named `conf/data_files.txt`. **NOTE: `set_amazon_ssds.pl` formats the SSD devices by default**. Please use it with caution.
After `data_files.txt` is generated, users need to set the parameter `root_conf` in the config file to specify the data directories of SAFS. In the default config file `conf/run_amazon.txt`, `root_conf` points to `/home/ubuntu/FlashX/conf/data_files.txt`, which is the location where the `conf/set_amazon_ssds.pl` script generates `data_files.txt`.

Users can follow the steps below to configure FlashX for SSDs in an Amazon instance. We assume the current directory is `/home/ubuntu/FlashX`.
* step 1: edit `conf/ssds.txt`. For example, the i2.xlarge instance has only one SSD device `xvdb`. `conf/ssds.txt` only need to contain one line:
```
xvdb
```

* step 2: `sudo perl conf/set_amazon_ssds.pl conf/ssds.txt`. This script mounts the SSDs and sets the data config file `conf/data_files.txt`. Users can use `utils/SAFS-util conf/run_amazon.txt list` to check if the SAFS is setup correctly. The command right now doesn't list any files because SAFS doesn't contain any files right now.

* step 3: load graph files to SAFS. In this case, we assume users have created graph files `wiki-Vote.adj` and `wiki-Vote.index`. Please refer to [Run FlashGraph](https://github.com/zheng-da/FlashX/wiki/FlashX-Quick-Start-Guide#run-flashgraph) for more details.
```
build/utils/SAFS-util conf/run_amazon.txt load wiki-Vote.adj wiki-Vote.adj
build/utils/SAFS-util conf/run_amazon.txt load wiki-Vote.index wiki-Vote.index
```
In addition, users can use the following command to verify whether the graph files are loaded to SAFS correctly.
```
build/utils/SAFS-util conf/run_amazon.txt verify wiki-Vote.adj wiki-Vote.adj
build/utils/SAFS-util conf/run_amazon.txt verify wiki-Vote.index wiki-Vote.index
```