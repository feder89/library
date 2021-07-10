import { Component, OnInit, OnChanges, SimpleChanges, Input } from '@angular/core';
import { MessageService } from 'primeng/components/common/messageservice';
import { PublisherService } from 'src/app/services/publisher.service';
import { Utils } from 'src/app/util/utils';
import { Publisher } from 'src/app/interfaces/publisher';
import { AppComponent } from 'src/app/app.component';
import { PublisherComponent } from '../publisher.component';
import { WholesalerService } from 'src/app/services/wholesaler.service';
import { Wholesaler } from 'src/app/interfaces/wholesaler';

@Component({
  selector: 'app-publisher-detail',
  templateUrl: './publisher-detail.component.html',
  styleUrls: ['./publisher-detail.component.css']
})
export class PublisherDetailComponent implements OnChanges {
  private mapper: Utils = new Utils();
  @Input() publisherId: number;
  public publisher: Publisher;
  public wholesalers: Wholesaler[];

  constructor(private publisherService: PublisherService,
    private messageService: MessageService,
    private app: AppComponent,
    private publisherComponent: PublisherComponent) { }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['publisherId'] && changes['publisherId'].currentValue != null) {
      this.loadPublisherInfo(changes['publisherId'].currentValue);
    } else {
      this.initPublisher();
    }
  }

  private initPublisher(): void {
    this.publisher = {
      id: null,
      nome: '',
      iva: '',
      indirizzo: '',
      citta: '',
      provincia: '',
      mail: '',
      telefono: '',
      cap: ''
    };
  }

  private loadPublisherInfo(idPublisher: number): void {
    this.publisherService.getPublishers(idPublisher).subscribe(res => {
      this.publisher = res[0];
    });
  }

  public save(): void {
    if (this.publisherId != null) {
      this.updatePublisher();
    } else {
      this.insertPublisher();
    }
  }

  private updatePublisher(): void {
    this.publisherService.updatePublisher(this.publisher)
      .subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Casa Editrice modificata');
          this.publisherComponent.displayDetailDialog = false;
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
  }

  private insertPublisher(): void {
    this.publisherService.createPublisher(this.mapper.mapperPublisherToBeInserted(this.publisher)).subscribe(
      res => {
        this.app.handleToastMessages('success', 'Completato', 'Casa Editrice creata');
        this.publisherComponent.displayDetailDialog = false;
      },
      error => {
        this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
      }
    );
  }

}
