LXA FairyTux 2
==============

The FairyTux 2 is a Octavo STM32MP1 SiP-based board like the MC-1,
but unlike it, exclusively boots from eMMC.

Initial Setup
-------------

If the eMMC is unprovisioned, the system must be bootstrapped via USB DFU
initially.

On your development host, run:

.. code-block:: bash

  $ cd platform-v7a/images
  $ dfu-util --alt 1 -D stm32mp1-tf-a-stm32mp153c-lxa-fairytux2.stm32
  $ dfu-util --alt 3 -D stm32mp153c-lxa-fairytux2.fip
  $ dfu-util --alt 0 -e

Or via Labgrid:

.. code-block:: bash

  $ cd platform-v7a/images
  $ labgrid-client dfu download 1 stm32mp1-tf-a-stm32mp153c-lxa-fairytux2.stm32
  $ labgrid-client dfu download 3 stm32mp153c-lxa-fairytux2.fip
  $ labgrid-client dfu detach 0

Then flash the eMMC via Android Fastboot from your development host:

.. code-block:: bash

  $ fastboot flash bbu-mmc stm32mp153c-lxa-fairytux2-emmcboot.img

Now Barebox will start from the eMMC boot partition on future boots.

Flashing the eMMC
-----------------

When the board is running barebox,
you can populate the eMMC with the Linux and userspace image with Fastboot:

.. code-block:: bash

  $ fastboot flash mmc1 lxa-fairytux2.hdimg

When Fastboot has finished, type ``boot`` on the Barebox prompt.

Maintenance Status
------------------

Pengutronix has at least two boards running in a remote lab (labgrid place names
``gutefee-00001`` (Gen 1) and ``gutefee-00011`` (Gen 2)).
