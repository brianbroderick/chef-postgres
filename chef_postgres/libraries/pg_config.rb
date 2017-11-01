# frozen_string_literal: true
# Based heavily on the guidelines from this page:
# https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server

class Chef
  class Provider
    class PgConfig < Chef::Provider::LWRPBase
      attr_reader :node, :workload

      def self.call(*args)
        new(*args).call
      end

      def initialize(node)
        @node = node
        @workload = node["chef_postgres"]["workload"].to_sym

        node.default["chef_postgres"]["pg_config"]["random_page_cost"] = 3.0
        node.default["chef_postgres"]["pg_config"]["synchronous_commit"] = "on"
      end

      def call
        { memory: memory,
          max_connections: max_connections,
          shared_buffers: shared_buffers,
          effective_cache_size: effective_cache_size,
          work_memory: work_memory,
          maintenance_work_memory: maintenance_work_memory,
          checkpoint_segments_or_max_wal_size: checkpoint_segments_or_max_wal_size,
          checkpoint_completion_target: checkpoint_completion_target,
          default_statistics_target: default_statistics_target,
          random_page_cost: random_page_cost,
          synchronous_commit: synchronous_commit,
          data_directory: data_directory,
          wal_keep_segments: wal_keep_segments }
      end

      def data_directory
        node["chef_postgres"]["pg_config"]["data_directory"]
      end

      def max_connections
        { web:  [500, connection_math(10)].min,
          oltp: [500, connection_math(10)].min,
          dw:   [100, connection_math(30)].min,
          mixed: [200, connection_math(15)].min,
          desktop: [50, (connection_math(20)].min }.fetch(workload)
      end

      def connection_math(desired_work_mem)
        # round to the nearest 10 connections using desired_work_mem in MB as a guide.
        # For example, if you have 990 MB of memory and want a desired_work_mem around 10MB, this will return 100
        (effective_cache / desired_work_mem).round(-1)
      end

      def ohai_memory
        node["memory"]["total"]
      end

      def memory # in MB
        @memory ||= ohai_memory.split("kB")[0].to_i / 1024
      end

      def shared_buffers
        # The shared_buffers configuration parameter determines how much memory is dedicated
        # to PostgreSQL to use for caching data. Use 15% if less than 1GB of memory
        # Due to binary rounding, 1GB may be represented at about 960MB

        buffers = if memory <= 950
                    memory * 0.15
                  else
                    { web: memory / 4,
                      oltp: memory / 4,
                      dw: memory / 4,
                      mixed: memory / 4,
                      desktop: memory / 16,
                    }.fetch(workload)
                  end

        # Cap at 2GB for 32bit or 8GB for 64bit
        case node["kernel"]["machine"]
        when "i386" # 32-bit machines max 2GB
          buffers = [buffers, 2048].min
        when "x86_64" # 64-bit machines max 8GB
          buffers = [buffers, 8192].min
        end

        ::BinaryRound.call(buffers)
      end

      def effective_cache_size_large
        # For machines with more than 16GB of RAM, leave 4GB for the OS and other apps for dedicated DB servers.
        { web: memory - 4096,
          oltp: memory - 4096,
          dw: memory - 4096,
          mixed: memory - 4096,
          desktop: memory / 4,
        }.fetch(workload)
      end      

      def effective_cache_size_small
        { web: memory * 3 / 4,
          oltp: memory * 3 / 4,
          dw: memory * 3 / 4,
          mixed: memory * 3 / 4,
          desktop: memory / 4,
        }.fetch(workload)
      end   

      def effective_cache
        # Estimate of how much memory is available for disk caching by the operating system
        # and within the database itself, after taking into account what's used by the OS itself
        # and other applications

        @effective_cache ||= (memory > 16384) ? effective_cache_size_large : effective_cache_size_small
      end         

      def effective_cache_size        
        ::BinaryRound.call(effective_cache)
      end

      def max_connections
        { web:  [500, connection_math(10)].min,
          oltp: [500, connection_math(10)].min,
          dw:   [100, connection_math(30)].min,
          mixed: [200, connection_math(15)].min,
          desktop: [50, (connection_math(20)].min }.fetch(workload)
      end

      def work_memory
        # This size is applied to each and every sort done by each user,
        # and complex queries can use multiple working memory sort buffers.

        memory_per_connection = (effective_cache.to_f / max_connections).ceil

        work_mem = { web: [20, memory_per_connection].min,
                     oltp: [20, memory_per_connection].min,
                     dw: [60, memory_per_connection * 0.85].min,
                     mixed: [30, memory_per_connection * 0.85].min,
                     desktop: [20, memory_per_connection * 0.15].min,
                   }.fetch(workload)

        ::BinaryRound.call(work_mem)
      end

      def maintenance_work_memory
        # Specifies the maximum amount of memory to be used by maintenance operations, such as VACUUM, CREATE INDEX

        maintenance_work_mem =
          [{ web: effective_cache / 12,
             oltp: effective_cache / 12,
             dw: effective_cache / 6,
             mixed: effective_cache / 12,
             desktop: effective_cache / 24,
           }.fetch(workload),
           4096,
          ].min

        ::BinaryRound.call(maintenance_work_mem)
      end

      def wal_keep_segments
        # Convert to modifier % of available disk space on log drive in MB, then divide by 16MB
        # If log location becomes configurable, the drive needs to also become configurable

        modifier = { web: 0.50,
                     oltp: 0.50,
                     dw: 0.50,
                     mixed: 0.50,
                     desktop: 0.25,
        }.fetch(workload)

        (node["filesystem"]["/dev/xvda1"]["kb_available"].to_f * modifier / 1024 / 16).round
      end

      def checkpoint_segments_or_max_wal_size
        # PostgreSQL writes new transactions to the database in files called WAL segments
        # that are 16MB in size. Every time checkpoint_segments worth of these files have been written,
        # by default 3, a checkpoint occurs.

        segments =
          { web: 8,
            oltp: 16,
            dw: 64,
            mixed: 16,
            desktop: 3,
          }.fetch(workload)

        if version.to_f >= 9.5
          "max_wal_size = " + ((3 * segments) * 16).to_s + "MB"
        else
          "checkpoint_segments = " + segments.to_s
        end
      end

      def checkpoint_completion_target
        # Time spent flushing dirty buffers during checkpoint, as fraction of the checkpoint interval.

        { web: "0.7",
          oltp: "0.9",
          dw: "0.9",
          mixed: "0.9",
          desktop: "0.5",
        }.fetch(workload)
      end

      def default_statistics_target
        # PG collects statistics about each of the tables in the database
        # to decide how to execute queries against it. This helps the query planner
        # get more accurate stats.

        { web: 100,
          oltp: 100,
          dw: 500,
          mixed: 100,
          desktop: 100,
        }.fetch(workload)
      end

      def random_page_cost
        # The default is 4, but most recommend between 2-3 with modern drives.

        node["chef_postgres"]["pg_config"]["random_page_cost"]
      end

      def synchronous_commit
        # TL;DR Turn this off to get a speed boost from your hard drives, but only in cases where it's ok to lose some data if the server loses power.
        # For example, in idempotent workloads. "on" is the safest.
        #
        # From https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server:
        # PostgreSQL can only safely use a write cache if it has a battery backup.
        # You may be limited to approximately 100 transaction commits per second per client in situations where you don't have such a durable write cache
        # (and perhaps only 500/second even with lots of clients).
        # For situations where a small amount of data loss is acceptable in return for a large boost in how many updates you can do to the database per second,
        # consider switching synchronous commit off. This is particularly useful in the situation where you do not have a battery-backed write cache on your disk controller,
        # because you could potentially get thousands of commits per second instead of just a few hundred.
        # For obsolete versions of PostgreSQL, you may find people recommending that you set fsync=off to speed up writes on busy systems.
        # This is dangerous--a power loss could result in your database getting corrupted and not able to start again.
        # Synchronous commit doesn't introduce the risk of corruption, which is really bad, just some risk of data loss

        node["chef_postgres"]["pg_config"]["synchronous_commit"]
      end

      def version
        node["chef_postgres"]["version"]
      end
    end
  end
end
