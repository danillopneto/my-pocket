import { UtilityService } from './services/utility.service';
import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  title = 'my-pocket';
  loading: boolean;

  constructor(private util: UtilityService) {
      this.util.loading.subscribe(
        (loading) => {
          this.loading = loading;
        }
     );
  }

  ngOnInit() {
  }
}
