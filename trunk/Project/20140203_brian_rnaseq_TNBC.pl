#!/usr/bin/perl
use strict;
use warnings;

use CQS::ClassFactory;
use CQS::FileUtils;

my $target_dir = create_directory_or_die("/scratch/cqs/shengq1/rnaseq/20140203_brian_rnaseq_TNBC");

my $fasta_file           = "/data/cqs/guoy1/reference/hg19/bwa_index_0.7.4/hg19_chr.fa";
my $transcript_gtf       = "/scratch/cqs/shengq1/references/hg19/Homo_sapiens.GRCh37.73.gtf";
my $transcript_gtf_index = "/scratch/cqs/shengq1/gtfindex/hg19_GRCh37_73";

my $hg19_gff = "/scratch/cqs/shengq1/references/hg19/dexseq_gff/Homo_sapiens.GRCh37.73.dexseq.gff";
my $hg19_map = "/scratch/cqs/shengq1/references/hg19/Homo_sapiens.GRCh37.73.map";

my $bowtie2_index = "/data/cqs/guoy1/reference/hg19/bowtie2_index/hg19";

my $annovar_param = "-protocol refGene,snp137,cosmic64,esp6500si_all,1000g2012apr_all -operation g,f,f,f,f --remove --otherinfo";
my $annovar_db    = "/scratch/cqs/shengq1/references/annovar/humandb/";

my $cqstools = "/home/shengq1/cqstools/CQS.Tools.exe";

my $email = "quanhu.sheng\@vanderbilt.edu";
my $task  = "20140203_brian";

#cqstools file_def -i /data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3 -n \(.+_\)L001_\(.+\)_001
my $files = {
  "30-PA_S1_R1" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/30-PA_S1_L001_R1_001.fastq.gz"],
  "30-PA_S1_R2" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/30-PA_S1_L001_R2_001.fastq.gz"],
  "30-SB_S2_R1" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/30-SB_S2_L001_R1_001.fastq.gz"],
  "30-SB_S2_R2" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/30-SB_S2_L001_R2_001.fastq.gz"],
  "30-TA_S3_R1" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/30-TA_S3_L001_R1_001.fastq.gz"],
  "30-TA_S3_R2" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/30-TA_S3_L001_R2_001.fastq.gz"],
  "40-PA_S4_R1" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/40-PA_S4_L001_R1_001.fastq.gz"],
  "40-PA_S4_R2" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/40-PA_S4_L001_R2_001.fastq.gz"],
  "40-TXA_S5_R1" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/40-TXA_S5_L001_R1_001.fastq.gz"],
  "40-TXA_S5_R2" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/40-TXA_S5_L001_R2_001.fastq.gz"],
  "42-PC_S6_R1" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/42-PC_S6_L001_R1_001.fastq.gz"],
  "42-PC_S6_R2" => ["/data/lehmanbd/insight_seq/TNBC_RNA-seq_phaseI/Run_3/42-PC_S6_L001_R2_001.fastq.gz"],
};

my $config = {
  general => { task_name => $task },
  files   => $files,
  fastqc  => {
    class      => "FastQC",
    perform    => 1,
    target_dir => "${target_dir}/fastqc",
    option     => "",
    source_ref => "files",
    sh_direct  => 0,
    pbs        => {
      "email"    => $email,
      "nodes"    => "1:ppn=2",
      "walltime" => "2",
      "mem"      => "10gb"
    },
  },
  tophat2 => {
    class                => "Tophat2",
    perform              => 1,
    target_dir           => "${target_dir}/tophat2",
    option               => "--segment-length 25 -r 0 -p 6",
    source_ref           => "files",
    bowtie2_index        => $bowtie2_index,
    transcript_gtf       => $transcript_gtf,
    transcript_gtf_index => $transcript_gtf_index,
    rename_bam           => 1,
    sh_direct            => 0,
    pbs                  => {
      "email"    => $email,
      "nodes"    => "1:ppn=6",
      "walltime" => "72",
      "mem"      => "30gb"
    },
  },
  sortbam => {
    class         => "Sortbam",
    perform       => 1,
    target_dir    => "${target_dir}/sortname",
    option        => "",
    source_ref    => "tophat2",
    sort_by_query => 1,
    sh_direct     => 0,
    pbs           => {
      "email"    => $email,
      "nodes"    => "1:ppn=8",
      "walltime" => "72",
      "mem"      => "20gb"
    },
  },
  htseqcount => {
    class      => "HTSeqCount",
    perform    => 1,
    target_dir => "${target_dir}/htseqcount",
    option     => "",
    source_ref => "sortbam",
    gff_file   => $transcript_gtf,
    sh_direct  => 0,
    pbs        => {
      "email"    => $email,
      "nodes"    => "1:ppn=1",
      "walltime" => "72",
      "mem"      => "40gb"
    },
  },
  genetable => {
    class         => "CQSDatatable",
    perform       => 1,
    target_dir    => "${target_dir}/genetable",
    option        => "-p ENS --noheader -o ${task}_gene.count",
    source_ref    => "htseqcount",
    name_map_file => $hg19_map,
    cqs_tools     => $cqstools,
    sh_direct     => 1,
    pbs           => {
      "email"    => $email,
      "nodes"    => "1:ppn=1",
      "walltime" => "10",
      "mem"      => "10gb"
    },
  },
  dexseqcount => {
    class        => "DexseqCount",
    perform      => 1,
    target_dir   => "${target_dir}/dexseqcount",
    option       => "",
    source_ref   => "tophat2",
    gff_file     => $hg19_gff,
    dexseq_count => "/home/shengq1/pylibs/bin/dexseq_count.py",
    sh_direct    => 0,
    pbs          => {
      "email"    => $email,
      "nodes"    => "1:ppn=1",
      "walltime" => "72",
      "mem"      => "40gb"
    },
  },
  exontable => {
    class         => "CQSDatatable",
    perform       => 1,
    target_dir    => "${target_dir}/exontable",
    option        => "-p ENS --noheader -o ${task}_exon.count",
    name_map_file => $hg19_map,
    source_ref    => "dexseqcount",
    cqs_tools     => $cqstools,
    sh_direct     => 0,
    pbs           => {
      "email"    => $email,
      "nodes"    => "1:ppn=1",
      "walltime" => "10",
      "mem"      => "10gb"
    },
  },
  varscan2 => {
    class           => "VarScan2::Mpileup2snp",
    perform         => 1,
    target_dir      => "${target_dir}/varscan2",
    option          => "--min-coverage 10",
    mpileup_options => "-q 20",
    java_option     => "-Xmx40g",
    source_ref      => "tophat2",
    fasta_file      => $fasta_file,
    somatic_p_value => 0.05,
    sh_direct       => 0,
    VarScan2_jar    => "/home/shengq1/local/bin/VarScan.v2.3.5.jar",
    pbs             => {
      "email"    => $email,
      "nodes"    => "1:ppn=1",
      "walltime" => "72",
      "mem"      => "40gb"
    },
  },
  annovar_varscan2 => {
    class      => "Annovar",
    perform    => 1,
    target_dir => "${target_dir}/varscan2",
    option     => $annovar_param,
    source_ref => [ "varscan2", "\.vcf\$" ],
    annovar_db => $annovar_db,
    buildver   => "hg19",
    sh_direct  => 1,
    isvcf      => 1,
    pbs        => {
      "email"    => $email,
      "nodes"    => "1:ppn=1",
      "walltime" => "72",
      "mem"      => "10gb"
    },
  },
};

performConfig($config);

1;
