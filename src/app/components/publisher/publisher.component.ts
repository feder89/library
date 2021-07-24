import { Component, OnInit } from '@angular/core';
import { MessageService } from 'primeng/components/common/messageservice';
import { Publisher } from 'src/app/interfaces/publisher';
import { PublisherService } from 'src/app/services/publisher.service';
import { AppComponent } from 'src/app/app.component';

@Component({
  selector: 'app-publisher',
  templateUrl: './publisher.component.html',
  styleUrls: ['./publisher.component.css']
})
export class PublisherComponent implements OnInit {

  public publishers: Publisher[];
  public allPublishers: Publisher[];
  public displayDetailDialog: boolean;
  public publisherIdSeleted: number = null;

  public type: string = null;
  public value: string = null;
  private idToDelete: number = 0;

  constructor(private publisherService: PublisherService, private messageService: MessageService, private app: AppComponent) { }

  ngOnInit() {
    this.loadPublisher();
  }

  private loadPublisher(): void {
    this.publisherService.getPublishers().subscribe(
      res => {
        this.publishers = res;
        this.allPublishers = res;
      }
    );
  }

  public onAddPublisher(): void {
    this.displayDetailDialog = true;
  }

  public onSelectPublisher(el: number): void {
    this.publisherIdSeleted = el;
    this.displayDetailDialog = true;
  }

  public onDeletePublisher(el: number, nome:string): void {
    this.idToDelete=el;
    this.value=nome;
    this.type="Casa Editrice";
  }

  public closeDialog(): void {
    this.loadPublisher();
    this.publisherIdSeleted = null;
  }

  public filterPublishers(s: string) {
    this.publishers = this.allPublishers.filter((b) => {
      return b.nome.toLowerCase().indexOf(s) > -1;
    })
  }

  confirmDelete(evt) {
    if (evt == true) {
      this.publisherService.deletePublisher(this.idToDelete)
      .subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Casa editrice rimossa');
          this.loadPublisher();
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );

    }
    this.value = null;
    this.idToDelete = 0;
    this.type = null;
    
  }

}
