import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.conf.Configuration;

public class CountRecs {

  public static void main(String[] args) throws Exception {
    if (args.length != 2) {
      System.err.println("Usage: WordCount <input path> <output path>");
      System.exit(-1);
    }

    final Configuration conf = new Configuration();
    conf.set("mapred.textoutputformat.separator", "|");
    Job job = Job.getInstance(conf);

    //Job job = new Job();
    job.setJarByClass(CountRecs.class);
    job.setJobName("Count records");

    // We can ask for just 1 reducer:
    job.setNumReduceTasks(1); 

    FileInputFormat.addInputPath(job, new Path(args[0]));
    FileOutputFormat.setOutputPath(job, new Path(args[1]));

    job.setMapperClass(CountRecsMapper.class);
    job.setReducerClass(CountRecsReducer.class);

    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(IntWritable.class);
    
    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}
