import java.io.IOException;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

public class CleanMapper_311
    extends Mapper<LongWritable, Text, Text, Text> {

  private static final int MISSING = 9999;
  
  @Override
  public void map(LongWritable key, Text value, Context context)
      throws IOException, InterruptedException {
    
    String line = value.toString();
    String [] commaSplit = line.split(",");

    String result = "";

    int [] indexes = {0,1,3,4,5,6,25,28,38,39};

    if(commaSplit.length == 41){
      for(int i = 0; i < indexes.length; i++){
        String current = commaSplit[indexes[i]];
        if(i == (indexes.length - 1)){
          result += current;
        }
        else{
          result += current + ",";
        }
      }
    context.write(new Text(result), new Text(""));
    }
  }
}
